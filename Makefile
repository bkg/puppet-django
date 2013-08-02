prefix ?= $(HOME)/.puppet/modules
# Extract a list of dependencies with versions to install from the Forge.
deps = $(shell awk '/^dependency/ {print $$2$$3}' Modulefile)

all: build

depends:
	@for dep in $(deps); do \
		pkgname="$${dep%%,*}"; \
		[ -d $(prefix)/$${pkgname##*/} ] || \
			puppet module install "$$pkgname" --version "$${dep##*,}" --modulepath $(prefix); \
	done

$(prefix)/python:
	git clone https://github.com/puppetmodules/puppet-module-python.git $@

$(prefix)/nginx:
	git clone https://github.com/jfryman/puppet-nginx.git $@ && \
		git --git-dir=$@/.git --work-tree=$@ checkout 17d1edaf74

# Checkout git based dependencies.
checkouts: $(prefix)/python $(prefix)/nginx

build: depends checkouts

check:
	puppet parser --verbose validate $$(find . -name '*.pp')
