class { 'supervisord':
}

package { "MySQL-python":
  ensure => present,
}

vcsrepo { "/opt/pulseshims":
  ensure   => present,
  provider => "mercurial",
  source   => 'https://hg.mozilla.org/automation/pulseshims',
  revision => "f8fc683ea85e",
}
