cron { 'collectstats':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-collectstats $(hostname) && perl -Mlib=lib collectstats.pl",
  hour => '0',
  minute => '0',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'moco-ldap-check':
  ensure => 'present',
  command => "consul-do bugzilla-cron-moco-ldap-check $(hostname) && bugzilla-run-if-active /usr/local/bin/bugzilla-moco-ldap-check -cron -email",
  hour => '0',
  minute => '21',
  user => 'root',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'whine':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-whine $(hostname) && bugzilla-run-if-active perl -Mlib=lib whine.pl",
  minute => '*/15',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'prune-last-visit':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-prune-last-visit $(hostname) && bugzilla-run-if-active perl -Mlib=lib clean-bug-user-last-visit.pl",
  hour => '0',
  minute => '0',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'requestnagger':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-requestnagger $(hostname) && bugzilla-run-if-active perl -Mlib=lib extensions/RequestNagger/bin/send-request-nags.pl",
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

cron { 'userprofile':
  ensure => 'present',
  command => "cd /var/www/bugzilla && consul-do bugzilla-cron-userprofile $(hostname) && bugzilla-run-if-active perl -Mlib=lib extensions/UserProfile/bin/update.pl",
  hour => '0',
  minute => '30',
  user => 'apache',
  environment => [
    "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/opt/aws/bin",
  ],
}

