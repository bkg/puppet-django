# Create a Django stack using Nginx, Gunicorn, and PostgreSQL with PostGIS.
class django (
  $ensure = present,
  $owner = 'root',
  $group = 'root',
  $pythonversion = '2.7',
  $postgis = true,
  $nginx_workers = $::processorcount,
  $webroot = $django::params::webroot,
  $gunicorn_user = $django::params::gunicorn_user,
) inherits django::params {
  File {
    owner => $owner,
    group => $group,
  }
  if !defined(Class['nginx']) {
    # Declare params first so we can append to default proxy headers.
    class { 'nginx::params': } ->
    class { 'nginx':
      proxy_set_header => concat(
        $nginx::params::nx_proxy_set_header,
        ['X-Forwarded-Proto $scheme']
      ),
      server_tokens => off,
      worker_processes => $nginx_workers,
    }
  }
  class { 'python':
    dev => true,
    virtualenv => true,
    pip => true,
  }
  if !defined(Class['Postgresql::Server']) {
    include postgresql::server
  }
  if $postgis {
    include postgresql::server::postgis
  }
}
