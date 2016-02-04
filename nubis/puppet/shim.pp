package { "MySQL-python27":
  ensure => present,
}

package { "python27-pip":
  ensure => present,
}

python::pip { [
  'mozillapulse',
  'sqlsoup',
  'pytz',
]:
  ensure => 'present',
  require => [
    Package["python27-pip"],
  ],
}

python::pip { "mozlog":
  ensure => '1.6',
  require => [
    Package["python27-pip"],
  ],
}

# Haxor for borked package
exec { "install-supervisord":
  command => "yum -y install --nogpgcheck supervisor",
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}->
exec { "fix-supervisor-shebang":
  command => "file /usr/bin/supervisor* | grep -i 'Python script' | cut -d: -f1 | xargs sed -i -e '1c#!/usr/bin/env python26'",
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}->
exec { "enable supervisord":
  command => "chkconfig supervisord on",
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}->
file { "/etc/supervisord.d/shim.ini":
  ensure => present,
  source => "puppet:///nubis/files/shim.ini",
}

package { "mercurial-python27":
  ensure => present,
}

vcsrepo { "/opt/pulse/shims":
  ensure   => present,
  provider => "hg",
  source   => 'https://hg.mozilla.org/automation/pulseshims',
  revision => "f8fc683ea85e",
  require  => [
    Package["mercurial-python27"],
  ],
}
