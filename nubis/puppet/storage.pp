include nubis_storage
nubis::storage { "$project_name": }

yumrepo { 'ceph':
  descr    => 'Ceph',
  baseurl  => "http://download.ceph.com/rpm-hammer/el6/x86_64",
  priority => 2,
  enabled  => 1,
  gpgcheck => 1,
  gpgkey   => 'https://download.ceph.com/keys/release.asc',
}

### This should be in puppet-nubis-storage
package { "ceph":
  ensure => latest,
  require => Yumrepo['ceph'],
}

# need to fix #! to use python26
exec { "fix-ceph-shebang":
  command => "file /usr/bin/ceph* | grep -i 'Python script' | cut -d: -f1 | xargs sed -i -e '1c#!/usr/bin/env python26'",
  require => Package["ceph"],
  path => ['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin','/usr/local/bin'],
}

### puppet-nubis-storage

# Link to our mountpoint
file { "/var/www/bugzilla/data":
  ensure => 'link',
  target => "/data/$project_name/data",
}

# Link to our mountpoint
file { "/var/www/bugzilla/graphs":
  ensure => 'link',
  target => "/data/$project_name/graphs",
}
