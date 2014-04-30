# An individual Django application comprised of a PostgreSQL database, Nginx
# virtual host serving static files, and a Gunicorn WSGI daemon. PostGIS can
# optionally be enabled/disabled (defaults to enabled) for the database. Django
# will not be installed in the virtualenv by default since most applications
# will specify the version needed in their requirements.txt.

define django::app (
  $vhostname,
  $ensure = present,
  $staticdir = undef,
  $mediadir = undef,
  $ssl = false,
  $ssl_only = false,
  $dbuser = undef,
  $dbpass = '',
  $owner = $django::owner,
  $group = $django::group,
  $pythonversion = $django::pythonversion,
  $wsgiapp = "${name}.wsgi:application",
  $nginx_proxy = "${name}_app",
  $gunicorn_user = $django::gunicorn_user,
  $gunicorn_workers = $::processorcount * 2,
  $gunicorn_bind = "unix:/run/gunicorn/${name}.sock",
  $django = false,
  $geo = true,
) {
  $vhostdocroot = "$django::webroot/$vhostname"
  $projectdir = "$django::webroot/$vhostname/$name"
  $venvdir = "${vhostdocroot}/env"

  $dbname = $name
  $dbusername = $dbuser ? {
    undef => regsubst($vhostname, '\.[a-z]{3}*$', ''),
    default => $dbuser
  }

  # This runs mkdir -p as $owner so let it run as root and fix up ownership
  # after the fact.
  python::virtualenv { $venvdir: version => $pythonversion } ~>
  exec { "$vhostname-venv-perms":
    command => "chown -R ${owner}:${group} ${vhostdocroot}",
    unless => "test $(stat -c %U%G $venvdir) = ${owner}${group}",
  } ->
  file { $projectdir:
    ensure => directory,
    owner => $owner,
    group => $group,
  }

  if !defined(Nginx::Resource::Vhost[$vhostname]) {
    nginx::resource::vhost {$vhostname:
      ensure => $ensure,
      proxy => "http://$nginx_proxy",
    }
  }
  if !defined(Nginx::Resource::Upstream[$nginx_proxy]) {
    nginx::resource::upstream {"$nginx_proxy":
      ensure => $ensure,
      members => [$gunicorn_bind],
    }
  }
  nginx::resource::location {"${vhostname}-static":
    ensure => $ensure,
    location => '/static/',
    location_alias => $staticdir ? {
      undef => "$projectdir/$name/static/public/",
      default => $staticdir
    },
    vhost => $vhostname,
    ssl => $ssl,
    ssl_only => $ssl_only,
  }
  nginx::resource::location {"${vhostname}-media":
    ensure => $ensure,
    location => '/media/',
    location_alias => $mediadir ? {
      undef => "$projectdir/$name/media/",
      default => $mediadir
    },
    vhost => $vhostname,
    ssl => $ssl,
    ssl_only => $ssl_only,
  }

  # Cannot use python::pip here due to the requirement for uniquely named
  # resources and no available package name parameter for python::pip.
  exec { "$name-install-gunicorn":
    command => "$venvdir/bin/pip install gunicorn",
    creates => "$venvdir/bin/gunicorn",
    user => $owner,
    require => File[$projectdir],
  } ->
  python::gunicorn { $name:
    ensure => $ensure,
    virtualenv => $venvdir,
    mode => 'wsgi',
    dir => "${vhostdocroot}/${name}",
    bind => $gunicorn_bind,
    template => 'django/gunicorn.erb',
  }
  if $django {
    exec { "django-$name":
      command => "$venvdir/bin/pip install django",
      creates => "$venvdir/bin/django-admin.py",
      user => $owner,
      require => File[$projectdir],
    }
  }

  # Create the db and user
  postgresql::server::db {"$dbname":
    user => $dbusername,
    password => $dbpass,
  }
  if $geo {
    django::spatialdb {$dbname: dbname => $dbname}
  }
  # Trust database connections over local sockets.
  postgresql::server::pg_hba_rule {"$dbname django app user":
    type => 'local',
    database => $dbname,
    user => $dbusername,
    auth_method => 'trust',
    order => '000',
  }
  Class['::django'] -> Django::App[$name]
}
