# Unfortunately the need for this hack has arisen in more than one location
# when interfacing with third party modules. Permissions and ownership are
# a struggle to override with Puppet, so fix things up with this resource.
define django::chown (
  $dir,
  $owner,
  $group
) {
  exec { "chown -R ${owner}:${group} $dir":
    unless => "test $(stat -c %U%G $dir) = ${owner}${group}",
  }
}
