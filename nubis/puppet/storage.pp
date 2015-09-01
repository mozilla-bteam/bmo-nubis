include nubis_storage
nubis::storage { "$project_name": }

# Link to our mountpoint
file { "/var/www/bugzilla/data":
  ensure => 'link',
  target => "/data/$project_name",
}
