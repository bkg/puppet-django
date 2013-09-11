# Install PostGIS for PostgreSQL. Utilize Ubuntu GIS PPA if available.
class django::postgis ($pkgname = undef) {
  include postgresql::params
  if !$pkgname {
    case $::operatingsystem {
      'Ubuntu': {
        $postgis_name = "postgresql-$postgresql::params::version-postgis-2.0"
        include apt
        apt::ppa { 'ppa:ubuntugis/ubuntugis-unstable':
          before => Package[$postgis_name],
        }
      }
      'Debian': {
        $postgis_name = "postgresql-$postgresql::params::version-postgis"
      }
      default: {
        $postgis_name = $name
        if $postgis_name == undef {
          fail('Use PostGIS package name when not on Debian or Ubuntu')
        }
      }
    }
  } else {
    $postgis_name = $pkgname
  }
  include postgresql::devel
  package {$postgis_name: ensure => present}
}
