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

package {'supervisor':
  ensure => 'present',
  require => [
    Yumrepo['epel'],
  ],
}

service { 'supervisord':
  enable => true,
  require => [
    Package['supervisor'],
  ],
}

file { '/etc/supervisord.conf':
  ensure => present,
  source => 'puppet:///nubis/files/supervisord.conf',
  require => [
    Package['supervisor'],
  ],
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
    Package['supervisor'],
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
