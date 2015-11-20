file { "/etc/init.d/bugzilla-queue":
  ensure => present,
  source => "puppet:///nubis/files/bugzilla-queue.init",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

