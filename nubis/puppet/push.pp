file { '/etc/init.d/bugzilla-push':
  ensure => present,
  source => 'puppet:///nubis/files/bugzilla-push.init',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

