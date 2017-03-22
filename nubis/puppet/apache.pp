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
  port     => $port,
  check    => "/usr/local/bin/bugzilla-healthz",
  interval => '30s',
}

class {
    'apache':
        apache_version      => '2.4',
        apache_name         => 'httpd24',
        default_mods        => true,
        default_vhost       => false,
        default_confd_files => false,
        service_manage      => true,
        service_enable      => false,
        keepalive           => 'Off',
        service_ensure      => false;
    'apache::mod::remoteip':
        proxy_ips => [ '127.0.0.1', '10.0.0.0/8' ];
    'apache::mod::headers':
#    'apache::mod::perl': # Busted thanks to Amazon Linux mod24_perl ?!
}

# Enable /server-status
class { 'apache::mod::status':
}

# Enable /server-info
class { 'apache::mod::info':
}


apache::custom_config { 'mod_perl':
  content => "
  LoadModule perl_module modules/mod_perl.so
  PerlSwitches -w -T
  PerlPostConfigRequire /var/www/bugzilla/mod_perl.pl

  # This is set in mod_perl.pl, but varies based on urlbase ?!?!
  <Perl>
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
    port              => $port,
    default_vhost     => true,
    docroot           => $::install_root,
    docroot_owner     => 'root',
    docroot_group     => 'apache',
    block             => ['scm'],
    setenvif          => 'X-Forwarded-Proto https HTTPS=on',
    access_log_format => '%{X-Forwarded-For}i %l %{Bugzilla_login}C %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %T %v %D',
    access_log_pipe   => '|/usr/local/bin/apache-syslog.pl',
    error_log_pipe    => '|/usr/local/bin/apache-syslog.pl',
    custom_fragment   => 'PerlChildInitHandler "sub { Bugzilla::RNG::srand(); srand(); }"',
    headers           => [
      "set X-Nubis-Version ${project_version}",
      "set X-Nubis-Project ${project_name}",
      "set X-Nubis-Build   ${packer_build_name}",
    ],
    directories       => [
      {
        path            => $install_root,
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
    ],
    serveradmin       => 'bugzilla-admin@mozilla.org',
    serveraliases     => [
      '*.bugzilla.mozilla.org',
      '*.bmoattachments.org',
      'test1.bugzilla.mozilla.org',
      'test2.bugzilla.mozilla.org',
      'sub1.test1.bugzilla.mozilla.org',
      'sub2.test1.bugzilla.mozilla.org',
      'sub1.test2.bugzilla.mozilla.org'
    ],
    redirect_status   => [
      'gone',
    ],
    redirect_source   => [
      '/localconfig.js',
    ],
    redirect_dest     => [
      '',
    ],
    rewrites          => [
      {
        comment      => 'Redirect invalid domains to the main one (but not ELB health checks)',
        rewrite_cond => [
          '%{QUERY_STRING} !elb-health-check',
          '%{REQUEST_URI} !^/server-(status|info)$',
          '%{HTTP_HOST} !^bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^bug[0-9]+\.bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^test[12]\.bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^sub[12]\.test1\.bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^sub1\.test2\.bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^api-dev\.bugzilla\.mozilla\.org$',
          '%{HTTP_HOST} !^bug[0-9]+\.bmoattachments\.org$',
          # XXX: This whole redirect business to canonical url needs to be based on config/CanonicalServer
          '%{HTTP_HOST} !\.nubis\.allizom\.org$',
          '%{HTTP_HOST} !^bugzilla\.allizom\.org$',
        ],
        rewrite_rule => ['(.*) https://bugzilla.mozilla.org$1 [R=301,L]'],
      },
      {
        comment      => 'Skip robots.txt',
        rewrite_rule => ['^/robots.txt$ - [L]'],
      },
      {
        comment      => 'Redirect bug subdomains to the bug itself',
        rewrite_cond => ['%{SERVER_NAME} ^bug(\d+)\.(.*)'],
        rewrite_rule => ['^/$ https://%2/show_bug.cgi?id=%1 [R=302,L]'],
      },
      {
        comment      => 'Add quicksearch redirect',
        rewrite_rule => ['^/quicksearch\.html$ https://%{HTTP_HOST}/page.cgi?id=quicksearch.html [R=301]'],
      },
      {
        comment      => 'Add bugwritinghelp redirect',
        rewrite_rule => ['^/bugwritinghelp\.html$ https://%{HTTP_HOST}/page.cgi?id=bug-writing.html [R=301]'],
      },
      {
        comment      => 'Map URI containing only a bug number directly to bug',
        rewrite_rule => ['^/([0-9]+)$ https://%{HTTP_HOST}/show_bug.cgi?id=$1 [R=301,L]'],
      },
    ]
}
