# Create a Django stack using Nginx, Gunicorn, and PostgreSQL with PostGIS.
class django (
  $ensure = present,
  $geo = true,
  $nginx_workers = $::processorcount,
) {
  $gunicorn_helper = '/usr/local/sbin/gunicorn-debian'
  File {
    owner => 'root',
    group => 'root',
  }
  class { 'nginx': worker_processes => $nginx_workers }
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
  if $geo {
    include django::postgis
  }
}
