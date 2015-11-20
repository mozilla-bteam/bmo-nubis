file { "/etc/init.d/bugzilla-queue":
  ensure => present,
  source => "puppet:///nubis/files/bugzilla-queue.init",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

file { "/usr/local/bin/bugzilla-cloudwatch-queue-size":
  ensure => present,
  source => "puppet:///nubis/files/cloudwatch-queue-size",
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}

cron { 'cloudwatch-queue-size':
  ensure => 'present',
  command => "consul-do bugzilla-cloudwatch-queue-size $(hostname) && /usr/local/bin/bugzilla-cloudwatch-queue-size 2>&1 | logger -t bugzilla-cloudwatch-queue-size",
  hour => '*',
  minute => '*',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

