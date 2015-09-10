class { 'supervisord':
}

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
