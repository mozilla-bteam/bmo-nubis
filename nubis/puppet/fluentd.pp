class { 'fluentd':
  service_ensure => stopped
}

fluentd::configfile { 'apache': }

fluentd::source { 'apache_access':
  configfile => 'apache',
  type       => 'tail',
  format     => 'apache2',
  tag        => 'forward.apache.access',
  config     => {
    'path' => '/var/log/httpd/*access.log',
  },
}

fluentd::source { 'apache_error':
  configfile => 'apache',
  type       => 'tail',
  format     => '/^\[[^ ]* (?<time>[^\]]*)\] \[(?<level>[^\]]*)\] \[pid (?<pid>[^\]]*)\] \[client (?<client>[^\]]*)\] (?<message>.*)$/',
  tag        => 'forward.apache.error',
  config     => {
    'path' => '/var/log/httpd/*error*log',
  },
}
