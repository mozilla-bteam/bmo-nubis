cron { 'collectstats':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && /usr/bin/perl -Mlib=lib collectstats.pl',
  hour => '0',
  minute => '0',
  user => 'root',
}

cron { 'whine':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && /usr/bin/perl -Mlib=lib whine.pl',
  minute => '*/15',
  user => 'apache',
}

cron { 'prune-last-visit':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && /usr/bin/perl -Mlib=lib clean-bug-user-last-visit.pl',
  hour => '0',
  minute => '0',
  user => 'apache',
}

cron { 'requestnagger':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && /usr/bin/perl -Mlib=lib extensions/RequestNagger/bin/send-request-nags.pl',
  hour => '0',
  minute => '30',
  user => 'apache',
}

cron { 'userprofile':
  ensure => 'present',
  command => 'cd /var/www/bugzilla && /usr/bin/perl -Mlib=lib extensions/UserProfile/bin/update.pl',
  hour => '0',
  minute => '30',
  user => 'apache',
}