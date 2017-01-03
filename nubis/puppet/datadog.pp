#XXX: duplicated from base
class { 'datadog_agent':
  api_key        => '%%DATADOG_API_KEY%%',
  service_ensure => 'stopped',
  service_enable => false,
  proxy_host     => 'proxy.service.consul',
  proxy_port     => 3128,
}

class { 'datadog_agent::integrations::apache': }

class { 'datadog_agent::integrations::process':
  processes   => [
      {
          'name'          => 'httpd',
          'search_string' => ['httpd'],
          'exact_match'   => true,
      },
  ],
}

file { '/etc/nubis.d/datadog-fixup':
  source => 'puppet:///nubis/files/datadog-fixup',
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
}
