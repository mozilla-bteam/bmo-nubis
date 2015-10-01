#!/usr/bin/perl

use strict;
use Sys::Syslog;

openlog('apache', 'pid', 'user');
while (my $log = <STDIN>) {
    $log =~ s/((?:\bBugzilla_|\b)(?:password|token)=)[^ &]+/$1*/gi;
    syslog('notice', $log);
}
closelog();

