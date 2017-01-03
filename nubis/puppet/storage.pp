include nubis_storage

nubis::storage { $project_name:
  type  => 'efs',
  owner => 'apache',
  group => 'apache',
}

### puppet-nubis-storage

# Link to our mountpoint
file { '/var/www/bugzilla/data':
  ensure => 'link',
  target => "/data/${project_name}/data",
}

# Link to our mountpoint
file { '/var/www/bugzilla/graphs':
  ensure => 'link',
  target => "/data/${project_name}/graphs",
}
