# Main entry for puppet
#

# Here we are simply importing a custom application puppet file.
# Typically you will include things like Apache and other puppet modules
# which are included in the base image.
import 'skel.pp'
import 'apache.pp'
import 'storage.pp'
import 'cron.pp'
import 'shim.pp'
import 'push.pp'

package { 'epel-release':
  ensure => present,
}->
yumrepo { 'epel':
  enabled => true,
}->
package {
  [
    'ImageMagick-perl',
    'graphviz',
    'patchutils',
    'mod24_perl',
    'perl',
    'perl-devel',
    'perl-version',
    'perl-autodie',
    'openssl-devel',
    'perl-Module-Pluggable',
    'perl-Sys-Syslog',
    'perl-LWP-Protocol-https',
    'perl-Crypt-CBC',
    'perl-Crypt-DES',
    'perl-Crypt-DES_EDE3',
    'perl-CPAN',
    'perl-App-cpanminus',
    'perl-Authen-SASL',
    'perl-Cache-Memcached',
    'perl-DBD-MySQL',
    'perl-DBI',
    'perl-DateTime',
    'perl-Digest-SHA',
    'perl-Email-MIME',
    'perl-Email-MIME-Attachment-Stripper',
    'perl-Email-MIME-Encodings',
    'perl-Email-Reply',
    'perl-Email-Send',
    'perl-Encode-Detect',
    'perl-File-Find-Rule',
    'perl-GD',
    'perl-GDGraph',
    'perl-GDTextUtil',
    'perl-HTML-Parser',
    'perl-HTML-Scrubber',
    'perl-HTML-Tree',
    'perl-HTTP-Tiny',
    'perl-IO-stringy',
    'perl-JSON-XS',
    'perl-LDAP',
    'perl-Linux-Pid',
    'perl-MIME-tools',
    'perl-Mozilla-CA',
    'perl-Regexp-Common',
    'perl-SOAP-Lite',
    'perl-Template-Toolkit',
    'perl-Text-Diff',
    'perl-Test-Taint',
    'perl-Tie-IxHash',
    'perl-TimeDate',
    'perl-Time-Duration',
    'perl-URI',
    'perl-XML-Simple',
    'perl-XML-Twig',
    'perl-YAML-Syck',
    'perl-libwww-perl',
    'perl-Capture-Tiny',
    'perl-Carp',
    'perl-Data-Dumper',
    'perl-Exception-Class',
    'perl-GD-Barcode',
    'perl-Sub-Uplevel',
    'perl-Test-Deep',
    'perl-Test-Differences',
    'perl-Test-Exception',
    'perl-Test-Most',
    'perl-Test-NoWarnings',
    'perl-Test-Simple',
    'perl-Test-Warn',
  ]:
    ensure => present,
}

file { "/var/www/bugzilla/answers.txt":
  ensure => present,
  source => "puppet:///nubis/files/answers.txt",
}

file "/var/www/bugzilla/template_cache":
  ensure => 'directory',
  owner  => 'root',
  group  => 'apache',
  mode   => '0770',
}

file { "/usr/local/bin/bugzilla-install-dependencies":
  ensure => present,
  source => "puppet:///nubis/files/install-dependencies",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { "/usr/local/bin/bugzilla-update":
  ensure => present,
  source => "puppet:///nubis/files/update",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { "/usr/local/bin/bugzilla-params-update":
  ensure => present,
  source => "puppet:///nubis/files/params-update",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { "/etc/confd":
  ensure  => directory,
  recurse => true,
  purge => false,
  owner => 'root',
  group => 'root',
  source => "puppet:///nubis/files/confd",
}
