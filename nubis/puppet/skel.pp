# This application specific puppet file is where we do work that is not
#+ already included in other puppet modules.
#
# There are a number of examples in here for installing packages as well
#+ as working with files and templates.
#
# Feel free to remove any of these that you do not need for your project.
#

exec { 'apt-get update':
  command => '/usr/bin/apt-get update',
}

package { 'makepasswd':
  ensure => '1.10-9',
  require  => Exec['apt-get update'],
}

package { 'git':
  ensure => present,
  require  => Exec['apt-get update'],
}

file { '/etc/update-motd.d/55-nubis-welcome':
  source => 'puppet:///nubis/files/nubis-welcome',
  owner => 'root',
  group => 'root',
  mode  => '0755',
}

exec { 'motd update':
  command => '/bin/run-parts /etc/update-motd.d/ > /var/run/motd.dynamic',
  require  => File['/etc/update-motd.d/55-nubis-welcome'],
}
