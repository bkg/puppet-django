# Install PostGIS for PostgreSQL. Utilize Ubuntu GIS PPA if available.
class django::postgis {
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
      $postgis_name = $django::postgis
    }
  }
  if !$postgis_name or $postgis_name == true {
    fail("Specify PostGIS package name when using $::operatingsystem.")
  }
  # We need postgres dev libs installed to compile psycopg2 in a virtualenv.
  include postgresql::lib::devel
  package { $postgis_name: ensure => present }
}
