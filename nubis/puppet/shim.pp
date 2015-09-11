package { "MySQL-python27":
  ensure => present,
}

package { "python27-pip":
  ensure => present,
}

python::pip { [
  'mozillapulse',
  'mozlog',
  'sqlsoup',
  'pytz',
]:
  ensure => 'present',
  require => [
    Package["python27-pip"],
  ],
}

# Haxor for borked package
exec { "install-supervisord":
  command => "yum -y install supervisor",
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}->
exec { "fix-supervisor-shebang":
  command => "file /usr/bin/supervisor* | grep -i 'Python script' | cut -d: -f1 | xargs sed -i -e '1c#!/usr/bin/env python26'",
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}->
class { 'supervisord':
  install_pip => false,
  package_provider => "yum",
  install_init => false,
}

package { "mercurial-python27":
  ensure => present,
}

vcsrepo { "/opt/pulseshims":
  ensure   => present,
  provider => "hg",
  source   => 'https://hg.mozilla.org/automation/pulseshims',
  revision => "f8fc683ea85e",
  require  => [
    Package["mercurial-python27"],
  ],
}
