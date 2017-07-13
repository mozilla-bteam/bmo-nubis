package { 'MySQL-python27':
  ensure => present,
}

package { 'python27-pip':
  ensure => present,
}

python::pip { [
  'mozillapulse',
  'sqlsoup',
  'pytz',
]:
  ensure  => 'present',
  require => [
    Package['python27-pip'],
  ],
}

python::pip { 'mozlog':
  ensure  => '1.6',
  require => [
    Package['python27-pip'],
  ],
}

python::pip { 'supervisor':
  ensure => '3.3.2',
  require => [
    Package['python27-pip'],
  ],
}

service { 'supervisord':
  enable => true,
  require => [
    Python::Pip['supervisor'],
    File['/etc/init.d/supervisord'],
  ],
}

file { '/etc/init.d/supervisord':
  ensure => present,
  source => 'puppet:///nubis/files/supervisord.init',
  owner   => 'root',
  group   => 'root',
}

file { '/etc/supervisord.conf':
  ensure => present,
  source => 'puppet:///nubis/files/supervisord.conf',
  owner   => 'root',
  group   => 'root',
}

file { '/etc/supervisord.d':
  ensure => 'directory',
  owner   => 'root',
  group   => 'root',
}

file { '/etc/supervisord.d/shim.ini':
  ensure => present,
  source => 'puppet:///nubis/files/shim.ini',
  require => [
    File['/etc/supervisord.d'],
  ],
}

package { 'mercurial-python27':
  ensure => present,
}

vcsrepo { '/opt/pulse/shims':
  ensure   => present,
  provider => 'hg',
  source   => 'https://hg.mozilla.org/automation/pulseshims',
  revision => 'f8fc683ea85e',
  require  => [
    Package['mercurial-python27'],
  ],
}
