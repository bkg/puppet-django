# Enable PostGIS for the database.
define django::spatialdb ($dbname, $pguser='postgres') {
  include django::postgis
  $psql = "sudo -u ${pguser} psql -d ${dbname} -c"
  exec { "${psql} 'CREATE EXTENSION postgis;'":
    unless => "${psql} 'select postgis_version();'",
    require => Postgresql::Db[$dbname],
  }
}

