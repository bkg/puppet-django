# Install PostGIS for PostgreSQL. Utilize Ubuntu GIS PPA if available.
class django::postgis {
  include postgresql::params
  case $::operatingsystem {
    'Ubuntu': {
      $pkgname = "postgresql-$postgresql::params::version-postgis-2.0"
      include apt
      apt::ppa { 'ppa:ubuntugis/ubuntugis-unstable':
        before => Package[$pkgname],
      }
    }
    'Debian': {
      $pkgname = "postgresql-$postgresql::params::version-postgis"
    }
    default: {
      $pkgname = $name
      if $pkgname == undef {
        fail('Use PostGIS package name when not on Debian or Ubuntu')
      }
    }
  }
  include postgresql::devel
  package { $pkgname:
    ensure => present,
  }
}
