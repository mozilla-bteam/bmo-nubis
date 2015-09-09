cron { 'collectstats':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && consul-do perl -Mlib=lib collectstats.pl',
  hour => '0',
  minute => '0',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'whine':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && consul-do bugzilla-$name perl -Mlib=lib whine.pl',
  minute => '*/15',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'prune-last-visit':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && consul-do bugzilla-$name perl -Mlib=lib clean-bug-user-last-visit.pl',
  hour => '0',
  minute => '0',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'requestnagger':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && consul-do bugzilla-$name perl -Mlib=lib extensions/RequestNagger/bin/send-request-nags.pl',
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'userprofile':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && consul-do bugzilla-$name perl -Mlib=lib extensions/UserProfile/bin/update.pl',
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}