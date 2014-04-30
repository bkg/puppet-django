# Install PostGIS for PostgreSQL. Utilize Ubuntu GIS PPA if available.
class django::postgis {
  if $::operatingsystem == 'Ubuntu' {
    include apt
    apt::ppa { 'ppa:ubuntugis/ubuntugis-unstable':
      before => Package[$django::postgis],
    }
  }
  # We need postgres dev libs installed to compile psycopg2 in a virtualenv.
  include postgresql::lib::devel
  package { $django::postgis: ensure => present }
}
