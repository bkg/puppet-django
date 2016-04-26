class django::params {
  $webroot = $::osfamily ? {
    /(?i-mx:debian)/ => '/var/www',
  }
  $gunicorn_user = $::osfamily ? {
    /(?i-mx:debian)/ => 'www-data',
  }
}
