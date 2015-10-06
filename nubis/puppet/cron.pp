cron { 'data-sync':
  ensure => 'present',
  command => "consul-do bugzilla-cron-data-sync $(hostname) && /usr/local/bin/bugzilla-data-sync 2>&1 | logger -t bugzilla-cron-data-sync",
  hour => '*',
  minute => '30',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'remove-idle-group-members':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-idle-group $(hostname) && perl -Mlib=lib scripts/remove_idle_group_members.pl 2>&1 | logger -t bugzilla-cron-idle-group",
  hour => '0',
  minute => '0',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'collectstats':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-collectstats $(hostname) && perl -Mlib=lib collectstats.pl 2>&1 | logger -t bugzilla-cron-collectstats",
  hour => '0',
  minute => '0',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'moco-ldap-check':
  ensure => 'present',
  command => "consul-do bugzilla-cron-moco-ldap-check $(hostname) && bugzilla-run-if-active /usr/local/bin/bugzilla-moco-ldap-check -cron -email 2>&1 | logger -t bugzilla-cron-moco-ldap-check",
  hour => '0',
  minute => '21',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'whine':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-whine $(hostname) && bugzilla-run-if-active perl -Mlib=lib whine.pl 2>&1 | logger -t bugzilla-cron-whine",
  minute => '*/15',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'prune-last-visit':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-prune-last-visit $(hostname) && bugzilla-run-if-active perl -Mlib=lib clean-bug-user-last-visit.pl 2>&1 | logger -t bugzilla-cron-prune-last-visit",
  hour => '0',
  minute => '0',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'requestnagger':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-requestnagger $(hostname) && bugzilla-run-if-active perl -Mlib=lib extensions/RequestNagger/bin/send-request-nags.pl 2>&1 | logger -t bugzilla-cron-requestnagger",
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'userprofile':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-userprofile $(hostname) && bugzilla-run-if-active perl -Mlib=lib extensions/UserProfile/bin/update.pl 2>&1 | logger -t bugzilla-cron-userprofile",
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

