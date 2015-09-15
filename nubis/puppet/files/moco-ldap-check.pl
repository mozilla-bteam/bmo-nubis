#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use feature 'state';
binmode STDOUT, ':utf8';
$| = 1;

# syntax:
#   moco-ldap-check [options]
# options:
#   -email   : send email
#   -cron    : supress stdout
#   -cache   : read cached files, not servers

use Data::Dumper;
use File::Slurp;
use FindBin qw( $RealBin );
use JSON;
use List::MoreUtils qw( uniq );
use LWP::Simple;
use LWP::UserAgent;
use MIME::Base64;
use Net::LDAP;
use Net::SMTP;
use URI::Escape qw( uri_escape );

# args
my $args = {};
{
    foreach my $arg (@ARGV) {
        if ($arg =~ /^-(.+)/) {
            $args->{$1} = 1;
        }
    }
    @ARGV = grep { !/^-/ } @ARGV;
}

# read configs
my $config = {};
{
    open(my $fh, '<', "$RealBin/config") or die "failed to read config: $!\n";
    while(<$fh>) {
        s/^([^#]+).*/$1/;
        s/(^\s+|\s+$)//g;
        next if $_ eq '';
        next unless /^([^\.]+)\.(\S+)\s+(.+)/;
        my ($group, $name, $value) = ($1, $2, $3);
        if (exists $config->{$group}->{$name}) {
            if (!ref($config->{$group}->{$name})) {
                $config->{$group}->{$name} = [ $config->{$group}->{$name} ];
            }
            push @{ $config->{$group}->{$name} }, $value;
        }
        else {
            $config->{$group}->{$name} = $value;
        }
    }
    close($fh);

    $config->{ignore}->{ldap} = [ $config->{ignore}->{ldap} ]
        unless ref($config->{ignore}->{ldap});
    $config->{ignore}->{bugzilla} = [ $config->{ignore}->{bugzilla} ]
        unless ref($config->{ignore}->{bugzilla});
    $config->{email}->{recipient} = [ $config->{email}->{recipient} ]
        unless ref($config->{email}->{recipient});
}

my $data_path = "$RealBin/data";
mkdir($data_path) unless -d $data_path;

# read users from ldap
my ($ldap_old, $ldap);
if ($args->{cache}) {
    $args->{cron} || print "loading cached ldap users..\n";
    $ldap_old = deserialise("$data_path/ldap_old");
    $ldap = deserialise("$data_path/ldap");
} else {
    $ldap_old = deserialise("$data_path/ldap");
    $ldap = {};
    $args->{cron} || print "reading ldap users..";
    my $ldap_server = Net::LDAP->new(
        $config->{ldap}->{server},
        scheme  => $config->{ldap}->{scheme},
        onerror => 'die',
        debug   => 0,
    ) or die $!;
    $ldap_server->bind($config->{ldap}->{user}, password => $config->{ldap}->{pass});
    my $count = 0;
    foreach my $ldap_base ('o=com,dc=mozilla', 'o=org,dc=mozilla') {
        my $result = $ldap_server->search(
            base   => $ldap_base,
            scope  => 'sub',
            filter => '(mail=*)',
            attrs  => ['mail', 'bugzillaEmail', 'emailAlias', 'zimbraAlias', 'cn', 'employeeType', 'manager'],
        );
        my $base_count = 0;
        foreach my $entry ($result->entries) {
            $base_count++;

            # grab values from ldap entry
            my ($name, $bugmail, $mail, $type, $manager) =
                map { $entry->get_value($_) || '' }
                qw(cn bugzillaEmail mail employeeType manager);
            next if $type eq 'DISABLED';

            next if grep { lc($_) eq lc(canon_email($mail)) } @{ $config->{ignore}->{ldap} };

            # sanitise bugmail
            $bugmail = '' if $bugmail !~ /\@/;
            $bugmail = trim($bugmail);
            if ($bugmail =~ / /) {
                $bugmail = (grep { /\@/ } split / /, $bugmail)[0];
            }

            # sanitise name
            $name =~ s/\s+/ /g;
            $name = trim($name);

            # store
            $ldap->{$mail} = {
                mail            => $mail,
                name            => $name,
                bugmail         => $bugmail,
                bugmail_canon   => canon_email($bugmail),
                manager         => $manager,
                organisation    => ($ldap_base eq 'o=com,dc=mozilla' ? 'corporation' : 'foundation'),
                aliases         => [],
            };
            my $aliases = [];
            foreach my $field (qw( emailAlias zimbraAlias )) {
                foreach my $alias (@{ $entry->get_value($field, asref => 1) || [] }) {
                    push @$aliases, canon_email($alias);
                }
            }
            $ldap->{$mail}->{aliases} = $aliases;
        }
        die "failed to find any LDAP entries in $ldap_base\n"
            unless $base_count;
        $count += $base_count;
    }
    $args->{cron} || print " $count\n";
}

# read users from bmo
my $bmo;
if ($args->{cache}) {
    $args->{cron} || print "loading cached bugzilla users..\n";
    $bmo = deserialise("$data_path/bmo");
} else {
    $bmo = {};
    $args->{cron} || print "reading bugzilla users..";

    my $url = 'https://bugzilla.mozilla.org/rest/group/mozilla-employee-confidential' .
        '?api_key=' . uri_escape($config->{bugzilla}->{api_key}) .
        '&membership=1';
    my $request = HTTP::Request->new(GET => $url);
    my $response = LWP::UserAgent->new(agent => 'moco-ldap-check')->request($request);
    die $response->message unless $response->is_success;
    my $entries = decode_json($response->decoded_content);

    my $count = 0;
    foreach my $entry (@{ $entries->{groups}->[0]->{membership} }) {
        next unless $entry->{can_login};
        $count++;
        my $login = lc($entry->{email});
        next if grep { lc($_) eq lc($login) } @{ $config->{ignore}->{bugzilla} };
        $bmo->{$login} = {
            login       => $login,
            login_canon => canon_email($login),
        };
    }
    $args->{cron} || print " $count\n";
}

# find matching ldap/bmo accounts
{
    foreach my $ldap_mail (sort keys %$ldap) {
        my @check;
        foreach my $mail (
            $ldap->{$ldap_mail}{bugmail},
            $ldap->{$ldap_mail}{bugmail_canon},
            $ldap_mail,
            @{ $ldap->{$ldap_mail}{aliases} },
        ) {
            push @check, $mail;
            push @check, canon_email($mail);
            if ($mail =~ /^([^\@]+)\@mozilla\.org$/) {
                my $part = $1;
                push @check, "$part\@mozilla.com";
                push @check, canon_email("$part\@mozilla.com");
            }
        }
        @check = uniq grep { $_ } @check;

        my $found = 0;
        foreach my $mail (@check) {
            foreach my $login (keys %$bmo) {
                next unless $login eq $mail || $bmo->{$login}->{login_canon} eq $mail;
                $bmo->{$login}->{ldap} = $mail;
                $ldap->{$ldap_mail}->{bmo} = $login;
                $found = 1;
                last;
            }
            last if $found;
        }
    }
}

# save current state
serialise("$data_path/ldap_old", $ldap_old);
serialise("$data_path/ldap", $ldap);
serialise("$data_path/bmo", $bmo);

# find new ldap accounts
my @ldap_new;
{
    $args->{cron} || print "finding new accounts..\n";
    foreach my $mail (sort keys %$ldap) {
        next if exists $ldap_old->{$mail};
        push @ldap_new, $ldap->{$mail};
    }
}

# find deleted ldap accounts
my @ldap_deleted_no_bmo;
my @ldap_deleted_disable_bmo;
my @ldap_deleted_update_bmo;
{
    $args->{cron} || print "finding deleted accounts..\n";
    foreach my $mail (sort keys %$ldap_old) {
        next if exists $ldap->{$mail};
        next if grep { $_ eq canon_email($mail) } @{ $config->{ignore}->{ldap} };

        if (!$ldap_old->{$mail}->{bmo}) {
            push @ldap_deleted_no_bmo, $ldap_old->{$mail};
        } elsif ($ldap_old->{$mail}->{bmo} =~ /\@(mozilla\.com|mozillafoundation\.org)$/i) {
            push @ldap_deleted_disable_bmo, $ldap_old->{$mail};
        } else {
            push @ldap_deleted_update_bmo, $ldap_old->{$mail};
        }
    }
}

# find ldap accounts where we could find their bmo account, but it doesn't
# match their bugmail value in ldap
my @ldap_wrong_bugmail;
{
    $args->{cron} || print "finding wrong bugmail values..\n";
    my @check;
    foreach my $mail (sort keys %$ldap) {
        next unless $ldap->{$mail}->{bmo};
        next if
            (
                $ldap->{$mail}->{bugmail}
                && (
                    lc($ldap->{$mail}->{bugmail}) eq lc($ldap->{$mail}->{bmo})
                    || lc($ldap->{$mail}->{bugmail_canon}) eq lc($ldap->{$mail}->{bmo})
                )
            ) || (
                !$ldap->{$mail}->{bugmail}
                && lc($mail) eq lc($ldap->{$mail}->{bmo})
            );
        push @check, $mail;
    }
    $args->{cron} || print "  checking " . scalar(@check) . " account" . (scalar(@check) == 1 ? '' : 's');
    my $users = bugzilla_users([ map { $ldap->{$_}->{bugmail} } @check ]);
    $args->{cron} || print "\n";
    my %seen = map { $_ => 0 } map { $ldap->{$_}->{bugmail} } @check;
    foreach my $user (@$users) {
        $seen{$user->{email}} = 1;
    }
    foreach my $mail (@check) {
        if ($seen{$ldap->{$mail}->{bugmail}}) {
            $ldap->{$mail}->{bmo} = $mail;
            next;
        }
        push @ldap_wrong_bugmail, $ldap->{$mail};
    }
}

# verify unmatched bugmail values against bmo
my @ldap_invalid_bugmail;
{
    $args->{cron} || print "finding invalid bugmail values..\n";
    my @check;
    foreach my $mail (sort keys %$ldap) {
        next unless $ldap->{$mail}->{bugmail};
        next if $ldap->{$mail}->{bmo};
        push @check, $mail;
    }
    $args->{cron} || print "  checking " . scalar(@check) . " account" . (scalar(@check) == 1 ? '' : 's');
    my $users = bugzilla_users([ map { $ldap->{$_}->{bugmail} } @check ]);
    $args->{cron} || print "\n";
    foreach my $mail (@check) {
        my $bugmail = $ldap->{$mail}->{bugmail};
        next if grep { $_->{email} eq $bugmail } @$users;
        push @ldap_invalid_bugmail, $ldap->{$mail};
    }
}

=cut
# find ldap accounts with mismatched moco/mofo group
# disabled because rest/group/ doesn't return how a user is added to the group
my @ldap_moco_mofo_mismatch;
{
    $args->{cron} || print "finding moco/mofo mismatch..\n";
    foreach my $mail (sort keys %$ldap) {
        next unless $ldap->{$mail}->{bmo} && exists $bmo->{$ldap->{$mail}->{bmo}};
        if (
            (
                $ldap->{$mail}->{organisation} eq 'corporation'
                && $bmo->{$ldap->{$mail}->{bmo}}->{group} ne 'mozilla-corporation'
            ) || (
                $ldap->{$mail}->{organisation} eq 'foundation'
                && $bmo->{$ldap->{$mail}->{bmo}}->{group} ne 'mozilla-foundation'
                && $ldap->{$mail}->{bmo} !~ /\@mozilla\.(com|org)$/
            )
        ) {
            push @ldap_moco_mofo_mismatch, $ldap->{$mail};
        }
    }
}
=cut

# find ldap accounts with unblessed bmo account
my @ldap_unblessed;
{
    $args->{cron} || print "finding unblessed accounts..\n";
    my @check;
    foreach my $mail (sort keys %$ldap) {
        next if $ldap->{$mail}->{bmo};
        next if grep { $_->{mail} eq $mail } @ldap_invalid_bugmail;
        push @check, $ldap->{$mail};
    }
    $args->{cron} || print "  checking " . scalar(@check) . " account" . (scalar(@check) == 1 ? '' : 's');
    my $users = bugzilla_users([ map { ($_->{bugmail}, $_->{mail}) } @check ]);
    $args->{cron} || print "\n";
    foreach my $check (@check) {
        my $mail = $check->{mail};
        foreach my $user (@$users) {
            next unless ldap_has_email($ldap->{$mail}, $user->{email});
            $ldap->{$mail}->{bmo} = $user->{email};
            last;
        }
    }
    foreach my $entry (@check) {
        next unless $entry->{bmo};
        push @ldap_unblessed, $entry;
    }
}

# find bmo accounts which aren't in ldap anymore
my @bmo_disable;
my @bmo_update;
{
    $args->{cron} || print "finding incorrectly blessed accounts..\n";
    foreach my $login (sort keys %$bmo) {
        my $found = 0;
        foreach my $mail (keys %$ldap) {
            if (check_email($ldap->{$mail}->{bmo}, $login)
                || ldap_has_email($ldap->{$mail}, $login)
            ) {
                $found = 1;
                last;
            }
        }
        next if $found;

        next if
            grep { $_->{bmo} && $_->{bmo} eq $login }
            (@ldap_deleted_disable_bmo, @ldap_deleted_update_bmo);
        if ($login =~ /\@(mozilla\.com|mozillafoundation\.org)$/i) {
            push @bmo_disable, $bmo->{$login};
        } else {
            push @bmo_update, $bmo->{$login};
        }
    }
}

my @report;
push @report, report(
    'ldap_new',
    'new ldap accounts',
    'no action required',
    \@ldap_new
);
push @report, report(
    'ldap_deleted_no_bmo',
    'deleted ldap accounts (no bmo account)',
    'no action required',
    \@ldap_deleted_no_bmo
);
push @report, report(
    'ldap_deleted_disable_bmo',
    'deleted ldap accounts (mo-co/mo-fo/mo-jp bmo account)',
    'disable bmo account',
    \@ldap_deleted_disable_bmo
);
push @report, report(
    'ldap_deleted_update_bmo',
    'deleted ldap accounts (external bmo account)',
    'remove from mo-co/mo-fo/mo-jp',
    \@ldap_deleted_update_bmo
);
push @report, report(
    'bmo_disable',
    'bugzilla accounts not in ldap',
    'disable bmo account',
    \@bmo_disable
);
push @report, report(
    'bmo_update',
    'bugzilla accounts not in ldap',
    'remove from mo-co/mo-fo/mo-jp',
    \@bmo_update
);
push @report, report(
    'ldap_unblessed',
    'ldap accounts without mo-co/mo-fo/mo-jp group',
    'verify, and add mo-co or mo-fo/mo-jp group to bmo account',
    \@ldap_unblessed
);
=cut
push @report, report(
    'ldap_moco_mofo_mismatch',
    'bmo accounts in the wrong mo-co/mo-fo/mo-jp group',
    'verify, and add adjust group membership if required',
    \@ldap_moco_mofo_mismatch
);
=cut
push @report, report(
    'ldap_wrong_bugmail',
    'ldap accounts with wrong bugmail',
    'ask owner to update phonebook',
    \@ldap_wrong_bugmail
);
push @report, report(
    'ldap_invalid_bugmail',
    'ldap accounts with invalid bugmail',
    'ask owner to update phonebook',
    \@ldap_invalid_bugmail
);

if ($args->{email} && @report) {
    my $smtp = Net::SMTP->new('localhost');
    $smtp->mail($config->{email}->{sender});
    foreach my $address (@{ $config->{email}->{recipient} }) {
        $smtp->to($address);
    }
    $smtp->data();
    $smtp->datasend("Subject: " . $config->{email}->{subject} . "\n");
    $smtp->datasend("X-Identity: moco-ldap-check\n");
    $smtp->datasend("Content-Type: text/plain; charset=UTF-8\n");
    $smtp->datasend("From: moco-ldap-check <moco-ldap-check\@mozilla.org>");
    $smtp->datasend("\n");
    $smtp->datasend(join("\n", @report));
    $smtp->dataend();
    $smtp->quit();
}

if (!$args->{cron}) {
    if (!scalar @report) {
        push @report, '**';
        push @report, '** nothing to report \o/';
        push @report, '**';
    }
    print join("\n", @report) . "\n";
}

sub report {
    my ($name, $title, $action, $entries) = @_;
    return unless my $count = scalar @$entries;

    my @report;
    push @report, '';
    push @report, '**';
    push @report, "** $title ($count)";
    push @report, "** [ $action ]";
    push @report, '**';
    push @report, '';

    my $max_length = 0;
    my @missing_name;
    foreach my $entry (@$entries) {
        $entry->{bmo} = $entry->{login}
            if exists $entry->{login};
        push @missing_name, $entry
            unless $entry->{name};
        $max_length = length($entry->{mail})
            if exists $entry->{mail} && length($entry->{mail}) > $max_length;
    }

    if (@missing_name) {
        my $users = bugzilla_users([ map { ($_->{bmo}) } @missing_name ]);
        foreach my $entry (@missing_name) {
            foreach my $user (@$users) {
                next unless $user->{email} eq $entry->{bmo};
                $entry->{name} = $user->{real_name};
                last;
            }
        }
    }

    foreach my $entry (@$entries) {
        if ($name eq 'ldap_wrong_bugmail') {
            push @report, sprintf(
                "%-${max_length}s %s (%s -> %s)",
                ($entry->{mail} ? $entry->{mail} : '-'),
                ($entry->{name} ? $entry->{name} : '-'),
                ($entry->{bugmail} ? $entry->{bugmail} : '-'),
                ($entry->{bmo} ? $entry->{bmo} : '-'),
            );
        } elsif ($name eq 'ldap_invalid_bugmail') {
            push @report, sprintf(
                "%-${max_length}s %s (%s)",
                ($entry->{mail} ? $entry->{mail} : '-'),
                ($entry->{name} ? $entry->{name} : '-'),
                ($entry->{bugmail} ? $entry->{bugmail} : '-'),
            );
        } else {
            push @report, sprintf(
                "%-${max_length}s %s (%s)",
                ($entry->{mail} ? $entry->{mail} : '-'),
                ($entry->{name} ? $entry->{name} : '-'),
                ($entry->{bmo} ? $entry->{bmo} : '-'),
            );
        }
    }

    return @report;
}

#
# utils
#

sub read_config_file {
    my ($filename) = @_;
    my @file;
    foreach my $line (read_file($filename)) {
        $line =~ s/^(.+)#.*$/$1/;
        $line = trim($line);
        next if $line eq '';
        push @file, $line;
    }
    return \@file;
}

sub clean_email {
    my $email = shift;
    $email = trim($email);
    $email = $1 if $email =~ /^(\S+)/;
    $email =~ s/&#64;/@/;
    $email = lc $email;
    return $email;
}

my $_canon_cache = {};
sub canon_email {
    my $email = shift;
    if (!exists $_canon_cache->{$email}) {
        my $canon = clean_email($email);
        $canon =~ s/^([^\+]+)\+[^\@]+(\@.+)$/$1$2/;
        $_canon_cache->{$email} = $canon;
    }
    return $_canon_cache->{$email};
}

sub trim {
    my $value = shift;
    $value =~ s/(^\s+|\s+$)//g;
    return $value;
}

sub serialise {
    my ($filename, $ref) = @_;
    state $json //= JSON->new->utf8->pretty->canonical;
    write_file($filename, $json->encode($ref));
}

sub deserialise {
    my ($filename) = @_;
    return decode_json(scalar read_file($filename));
}

my $_bugzilla;
sub bugzilla_users {
    my ($logins) = @_;
    die "no users" unless @$logins;

    my $url = 'https://bugzilla.mozilla.org/rest/user' .
        '?api_key=' . uri_escape($config->{bugzilla}->{api_key}) .
        '&include_fields=email,real_name,id' .
        '&match=' . join('&match=', map { uri_escape($_) } @$logins);
    my $request = HTTP::Request->new(GET => $url);
    my $response = LWP::UserAgent->new(agent => 'moco-ldap-check')->request($request);
    die $response->message unless $response->is_success;
    return decode_json($response->decoded_content)->{users};
}

sub ldap_has_email {
    my ($ldap, $check) = @_;
    return (
        check_email($ldap->{bugmail}, $check)
        or check_email($ldap->{mail}, $check)
        or (grep { check_email($_, $check) } @{ $ldap->{aliases} })
    ) ? 1 : 0;
}

{
    my $cache = {};
    sub check_email {
        my ($email, $check) = @_;
        return 0 unless $email;
        my $key = "$email $check";
        if (!exists $cache->{$key}) {
            $cache->{$key} = (
                $email eq $check
                or canon_email($email) eq $check
                or $email eq canon_email($check)
                or canon_email($email) eq canon_email($check)
            ) ? 1 : 0;
        }
        return $cache->{$key};
    }
}
