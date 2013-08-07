# Django Module

This module builds on a few great modules to provide a Django application
stack with PostgreSQL/PostGIS, Nginx, Gunicorn, and Virtualenv. It has been
primarily tested on Ubuntu Server 12.04 but should work with Debian as well.

# Quick Start

Install packages for PostgreSQL, PostGIS, Nginx, and Virtualenv:

    include django

Add a new Django application base. This creates an Nginx vhost config, fresh virtualenv, and a default
directory structure for deploying your application code:

    django::app { 'examplesite': vhostname => 'examplesite.com' }

Note that Django will not be installed in the virtualenv by default as that
is expected to be versioned and installed via a requirements.txt. Also, the db
user password is blank by default and we are trusting local socket connections
anyway. Finer grained control can be achieved with:

    django::app { 'examplesite':
      vhostname => 'examplesite.com',
      vhostroot => '/srv/www',
      staticdir => 'static/public',
      mediadir => 'media',
      dbuser => 'exampleuser',
      dbpass => 'md5d16f1d3e443f9fa954b3455d6cf56fdb',
      django => true,
    }
