define django::app (
  $vhostname,
  $ensure = present,
  $vhostroot = '/var/www',
  $staticdir = 'static/public',
  $mediadir = 'media',
  $dbuser = undef,
  $dbpass = '',
  $owner = 'root',
  $group = 'root',
  $django = false,
) {
  $dbname = $name
  if $dbuser {
    $dbusername = $dbuser
  } else {
    $dbusername = regsubst($vhostname, '\.[a-z]{3}*$', '')
  }
  $vhostdocroot = "${vhostroot}/${vhostname}"
  $venvdir = "${vhostdocroot}/env"
  python::virtualenv { $venvdir:
    owner => $owner,
    group => $group,
  } ->
  file { "$vhostdocroot/$name":
    ensure => directory,
    owner => $owner,
    group => $group,
  }

  nginx::resource::upstream {"${name}_app":
    ensure  => $ensure,
    members => [
      "unix:/var/run/gunicorn/${name}.sock",
    ],
  }
  nginx::resource::vhost {$vhostname:
    ensure => $ensure,
    proxy  => "http://${name}_app",
  }
  nginx::resource::location {$vhostname:
    ensure   => $ensure,
    location_alias => "${vhostdocroot}/${name}/${name}/${staticdir}/",
    location => '/static/',
    vhost    => $vhostname,
  }
  nginx::resource::location {"${vhostname}-media":
    ensure   => $ensure,
    location_alias => "${vhostdocroot}/${name}/${name}/${mediadir}/",
    location => '/media/',
    vhost    => $vhostname,
  }

  python::gunicorn { $name:
    ensure => $ensure,
    virtualenv  => $venvdir,
    mode        => 'django',
    dir         => "${vhostdocroot}/${name}",
    bind        => "unix:/var/run/gunicorn/${name}.sock",
    template    => 'django/gunicorn.erb',
  }
  python::pip { 'gunicorn':
    virtualenv  => $venvdir,
    owner => $owner,
    require => Python::Virtualenv[$venvdir],
  }
  if $django {
    python::pip { 'django':
      virtualenv  => $venvdir,
      owner => $owner,
      require => Python::Virtualenv[$venvdir],
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
  Class['::django'] -> Django::App[$name]
}