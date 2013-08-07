# Install PostGIS for PostgreSQL. Utilize Ubuntu GIS PPA if available.
class django::postgis {
  case $::operatingsystem {
    'Ubuntu': {
      $pkgname = 'postgresql-9.1-postgis-2.0'
      include apt
      apt::ppa { 'ppa:ubuntugis/ubuntugis-unstable':
        before => Package[$pkgname],
      }
    }
    'Debian': {
      $pkgname = 'postgresql-9.1-postgis'
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
