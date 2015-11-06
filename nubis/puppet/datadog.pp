#XXX: duplicated from base
class { 'datadog_agent':
  api_key => "%%DATADOG_API_KEY%%",
}

class { 'datadog_agent::integrations::apache': }

class { 'datadog_agent::integrations::process':
  processes   => [
      {
          'name'          => 'httpd',
          'search_string' => ['/usr/sbin/httpd'],
          'exact_match'   => true,
      },
  ],
}
