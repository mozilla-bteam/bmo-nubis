# Define how apache should be installed and configured.
# This uses the puppetlabs-apache puppet module [0].
#
# [0] https://github.com/puppetlabs/puppetlabs-apache
#

$service = 'bugzilla'
$install_root = '/var/www/bugzilla'
$port = 80

include nubis_discovery

nubis::discovery::service { $service:
  tags => [ 'apache','backend' ],
  port => $port,
  check => "/usr/bin/curl -I http://localhost:$port",
  interval => "30s",
}

class {
    'apache':
        apache_version      => '2.4',
        apache_name         => 'httpd24', 
        default_mods        => true,
        default_vhost       => false,
        default_confd_files => false,
	service_manage         => true,
        service_enable         => true,
        service_ensure         => false;
    'apache::mod::remoteip':
        proxy_ips => [ '127.0.0.1', '10.0.0.0/8' ];
    'apache::mod::headers':
#    'apache::mod::perl': # Busted thanks to Amazon Linux mod24_perl ?!
}

apache::custom_config { 'mod_perl':
  content => "
  LoadModule perl_module modules/mod_perl.so
  PerlSwitches -w -T
  PerlPostConfigRequire /var/www/bugzilla/mod_perl.pl

  # This is set in mod_perl.pl, but varies based on urlbase ?!?!
  <Perl>
    warn 'Setting Apache Sizelimit to 700M';
    use Apache2::SizeLimit;
    Apache2::SizeLimit->set_max_unshared_size(700_000);

    use Apache2::Const -compile => 'OK';

    # Set HTTPS for Bugzilla to detect ssl or not
    sub MY::FixupHandler {
      my \$r = shift;

      my \$args  = \$r->args();

      #ELB Health check
      if (\$args eq 'no-ssl-rewrite&elb-health-check') {
        # Cheat and pretend we are https, avoiding redirects
        \$r->subprocess_env('HTTPS' => 'on');
        return Apache2::Const::OK;
      }

      my \$proto = \$r->headers_in->get('X-Forwarded-Proto');
      
      if (\$proto eq 'https') {
        \$r->subprocess_env('HTTPS' => 'on');
      }
      
      return Apache2::Const::OK;
    } 
  </Perl>
",
}



apache::vhost { $service:
    port                        => $port,
    default_vhost               => true,
    docroot                     => $::install_root,
    docroot_owner               => 'root',
    docroot_group               => 'apache',
    block                       => ['scm'],
    setenvif                    => 'X_FORWARDED_PROTO https HTTPS=on',
    access_log_format           => '%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"',
    custom_fragment             => 'PerlChildInitHandler "sub { Bugzilla::RNG::srand(); srand(); }"',
    directories => [
      {
        path => $install_root,
        custom_fragment => '
    AddHandler perl-script .cgi
    # Fixup SSL detection
    PerlFixupHandler MY::FixupHandler
    # No need to PerlModule these because they are already defined in mod_perl.pl
    PerlResponseHandler Bugzilla::ModPerl::ResponseHandler
    PerlCleanupHandler  Apache2::SizeLimit Bugzilla::ModPerl::CleanupHandler
    PerlOptions +ParseHeaders
    Options +ExecCGI +FollowSymLinks
    AllowOverride Limit FileInfo Indexes
    DirectoryIndex index.cgi index.html	
	'
      },
    ]
}
