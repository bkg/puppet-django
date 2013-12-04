# Enable PostGIS for a database.
define django::spatialdb ($dbname, $pguser='postgres') {
  include django::postgis
  $psql = "psql -d $dbname -c"
  $cmd = inline_template('createlang -d <%= @dbname %> plpgsql
    POSTGIS_SQL_PATH=$(echo $(pg_config --sharedir)/contrib/postgis-*)
    psql -d <%= @dbname %> -f $POSTGIS_SQL_PATH/postgis.sql
    psql -d <%= @dbname %> -f $POSTGIS_SQL_PATH/spatial_ref_sys.sql
  ')
  # Install postgis from packaged scripts when <2.0.
  exec { "${dbname}-install-postgis":
    command => $cmd,
    unless => "$psql 'select postgis_version();' || test -f /usr/share/postgresql/*/extension/postgis.control",
    user => $pguser,
    require => Postgresql::Server::Db[$dbname],
  }
  # With PostGIS >= 2.0 we can take advantage of extension loading.
  exec { "${dbname}-create-postgis-extension":
    command => "$psql 'CREATE EXTENSION postgis;'",
    onlyif => "test -f /usr/share/postgresql/*/extension/postgis.control && ! $psql 'select postgis_version();'",
    user => $pguser,
    require => Postgresql::Server::Db[$dbname],
  }
}
