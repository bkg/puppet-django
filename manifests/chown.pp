# Unfortunately the need for this hack has arisen in more than one location
# when interfacing with third party modules. Permissions and ownership are
# a struggle to override with Puppet, so fix things up with this resource.
define django::chown (
  $owner,
  $group,
) {
  exec { "chown -R ${owner}:${group} $name":
    unless => "test $(stat -c %U%G $name) = ${owner}${group}",
  }
}
