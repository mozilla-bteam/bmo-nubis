package { 'epel-release':
  ensure => present,
}->
yumrepo { 'epel':
  enabled => true,
}->
package {
  [
    'git',
    'graphviz',
    'patchutils',
    'mod24_perl',
    'perl',
    'perl-devel',
    'openssl-devel',
    'gmp-devel',
    'perl-App-cpanminus',
    'mysql',
    'mysql-devel',
  ]:
    ensure => present,
}

file { '/var/www/bugzilla/answers.txt':
  ensure => present,
  source => 'puppet:///nubis/files/answers.txt',
}

file { '/var/www/bugzilla/template_cache':
  ensure => 'directory',
  owner  => 'root',
  group  => 'apache',
  mode   => '0770',
}

file { '/opt/bugzilla-moco-ldap-check':
  ensure => 'directory',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}->
file { '/opt/bugzilla-moco-ldap-check/check.pl':
  ensure => present,
  source => 'puppet:///nubis/files/moco-ldap-check.pl',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}->
file { '/usr/local/bin/bugzilla-moco-ldap-check':
  ensure => 'link',
  target => '/opt/bugzilla-moco-ldap-check/check.pl',
}

file { '/usr/local/bin/bugzilla-install-dependencies':
  ensure => present,
  source => 'puppet:///nubis/files/install-dependencies',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-monkeypatch':
  ensure => present,
  source => 'puppet:///nubis/files/monkeypatch',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-checksetup':
  ensure => present,
  source => 'puppet:///nubis/files/checksetup',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-update':
  ensure => present,
  source => 'puppet:///nubis/files/update',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-run-if-active':
  ensure => present,
  source => 'puppet:///nubis/files/run-if-active',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-purpose':
  ensure => present,
  source => 'puppet:///nubis/files/purpose',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-active':
  ensure => present,
  source => 'puppet:///nubis/files/active',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-passive':
  ensure => present,
  source => 'puppet:///nubis/files/passive',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-failover':
  ensure => present,
  source => 'puppet:///nubis/files/failover',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-data-sync':
  ensure => present,
  source => 'puppet:///nubis/files/data-sync',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/apache-syslog.pl':
  ensure => present,
  source => 'puppet:///nubis/files/apache-syslog.pl',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/usr/local/bin/bugzilla-healthz':
  ensure => present,
  source => 'puppet:///nubis/files/healthz',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { '/etc/confd':
  ensure  => directory,
  recurse => true,
  purge   => false,
  owner   => 'root',
  group   => 'root',
  source  => 'puppet:///nubis/files/confd',
}

include nubis_configuration
nubis::configuration{ 'bugzilla':
        format => 'sh',
}
