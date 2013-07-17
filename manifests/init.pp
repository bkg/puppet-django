# Create a Django stack using Nginx, Gunicorn, and PostgreSQL with PostGIS.
class django (
  $nginx_workers = $::processorcount,
  $owner = 'www-data',
  $geo = true,
) {
  class {'nginx':
    worker_processes => $nginx_workers,
  }
  class { 'python::venv':
    owner => $owner,
    group => $owner,
  } ->
  class { 'python::gunicorn':
    owner => $owner,
    group => $owner,
  }
  if $geo {
    include django::postgis
  }
}
