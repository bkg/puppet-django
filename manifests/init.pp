# Create a Django stack using Nginx, Gunicorn, and PostgreSQL with PostGIS.
class django (
  $nginx_workers = $::processorcount,
  $www_owner = 'www-data',
  $www_group = 'www-data',
  $geo = true,
) {
  class {'nginx':
    worker_processes => $nginx_workers,
  }
  # The Gunicorn daemon will run as $www_owner/group and it must be able to
  # install itself in the virtualenv.
  class { 'python::venv':
    owner => $www_owner,
    group => $www_group,
  } ->
  class { 'python::gunicorn':
    owner => $www_owner,
    group => $www_group,
  }
  if $geo {
    include django::postgis
  }
}
