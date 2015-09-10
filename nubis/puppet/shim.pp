class { 'supervisord':
}

package { "MySQL-python":
  ensure => present,
}

package {[
  'mozillapulse',
  'mozlog',
  'sqlsoup',
  'pytz',
]:
  provider => 'pip',
  ensure   => present;
}

package { "mercurial":
  ensure => present,
}

vcsrepo { "/opt/pulseshims":
  ensure   => present,
  provider => "hg",
  source   => 'https://hg.mozilla.org/automation/pulseshims',
  revision => "f8fc683ea85e",
  require  => [
    Package["mercurial"],
  ],
}
