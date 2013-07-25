define django::app (
  $vhostname,
  $vhostroot = '/var/www',
  $staticdir = 'static/public',
  $mediadir = 'media',
  $dbuser = undef,
  $dbpass = '',
  $django = false,
  $gunicorn_workers = $::processorcount * 2 + 1
) {
  $dbname = $name
  if $dbuser {
    $dbusername = $dbuser
  } else {
    $dbusername = regsubst($vhostname, '\.[a-z]{3}*$', '')
  }
  $vhostdocroot = "${vhostroot}/${vhostname}"
  $venvdir = "${vhostdocroot}/env"
  # Unfortunately there is currently no way to set separate ownership
  # for app and venv subdirs while allowing the gunicorn daemon to run as an
  # unprivileged user. Work around that here.
  python::venv::isolate { $venvdir: } ->
  exec { "chown root:root ${vhostdocroot}": } ->
  file { "$vhostdocroot/$name":
    ensure => directory,
  }

  nginx::resource::upstream {"${name}_app":
    ensure  => present,
    members => [
      "unix:/var/run/gunicorn/${name}.sock",
    ],
  }
  nginx::resource::vhost {$vhostname:
    ensure => present,
    proxy  => "http://${name}_app",
  }
  nginx::resource::location {$vhostname:
    ensure   => present,
    location_alias => "${vhostdocroot}/${name}/${name}/${staticdir}/",
    location => '/static/',
    vhost    => $vhostname,
  }
  nginx::resource::location {"${vhostname}-media":
    ensure   => present,
    location_alias => "${vhostdocroot}/${name}/${name}/${mediadir}/",
    location => '/media/',
    vhost    => $vhostname,
  }

  python::gunicorn::instance {$name:
    venv => $venvdir,
    src => "${vhostdocroot}/${name}",
    django => true,
    workers => $gunicorn_workers,
  }
  if $django {
    python::pip::install { 'django':
      venv => $venvdir,
      require => Python::Venv::Isolate[$venvdir],
    }
  }

  # Use the defaults, local ident access only for postgres superuser
  include postgresql::server
  # Create the db and user
  postgresql::db {"$dbname":
    user => $dbusername,
    password => $dbpass,
  } ->
  django::spatialdb {$dbname:
    dbname => $dbname,
  }
  # Trust database connections over local sockets.
  postgresql::pg_hba_rule {"$dbname django app user":
    type => 'local',
    database => $dbname,
    user => $dbusername,
    auth_method => 'trust',
    order => '000',
  }
}
