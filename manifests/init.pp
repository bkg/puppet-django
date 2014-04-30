# Create a Django stack using Nginx, Gunicorn, and PostgreSQL with PostGIS.
class django (
  $ensure = present,
  $owner = 'root',
  $group = 'root',
  $pythonversion = '2.7',
  $postgis = $django::params::postgis_name,
  $nginx_workers = $::processorcount,
  $webroot = $django::params::webroot,
  $gunicorn_user = $django::params::gunicorn_user,
) inherits django::params {
  $gunicorn_helper = '/usr/local/sbin/gunicorn-debian'

  File {
    owner => $owner,
    group => $group,
  }
  if !defined(Class['nginx']) {
    class { 'nginx': worker_processes => $nginx_workers }
  }
  class { 'python':
    dev => true,
    virtualenv => true,
    gunicorn => true,
    pip => true,
  }
  file { $gunicorn_helper:
    ensure => $ensure,
    mode => '0755',
    source => 'puppet:///modules/django/gunicorn-debian',
  }
  file { '/etc/default/gunicorn':
    content => "HELPER=$gunicorn_helper\n",
    ensure => $ensure,
    mode => '0644',
  }
  if $postgis {
    include django::postgis
  }
}
