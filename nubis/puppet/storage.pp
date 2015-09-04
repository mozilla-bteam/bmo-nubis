include nubis_storage
nubis::storage { "$project_name": }

### This should be in puppet-nubis-storage
package { "ceph":
  ensure => present,
}

# need to fix #! to use python26
exec { "fix-ceph-shebang":
  command => "sed -i -e '1c#!/usr/bin/env python26' /usr/bin/ceph*",
  require => Package["ceph"],
}

### puppet-nubis-storage

# Link to our mountpoint
file { "/var/www/bugzilla/data":
  ensure => 'link',
  target => "/data/$project_name",
}
