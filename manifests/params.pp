class django::params {
  require postgresql::server
  $webroot = $::osfamily ? {
    /(?i-mx:debian)/ => '/var/www',
  }
  $gunicorn_user = $::osfamily ? {
    /(?i-mx:debian)/ => 'www-data',
  }
  $postgis_version = $::lsbdistcodename ? {
    /(?i-mx:wheezy)/ => '1.5',
    /(?i-mx:jessie)/ => '2.1',
    default => '2.0'
  }
  $postgis_name = "postgresql-$postgresql::params::version-postgis-$postgis_version"
}
