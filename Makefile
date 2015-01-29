prefix ?= $(HOME)/.puppet/modules
manifests = $(wildcard manifests/*.pp)
# Extract a list of dependencies with versions to install from the Forge.
deps = $(shell awk '/^dependency/ {print $$2$$3}' Modulefile)

all: build

depends:
	@for dep in $(deps); do \
		pkgname="$${dep%%,*}"; \
		[ -d $(prefix)/$${pkgname##*/} ] || \
			puppet module install "$$pkgname" --version "$${dep##*,}" --modulepath $(prefix); \
	done

$(prefix)/supervisor:
	git clone https://github.com/plathrop/puppet-module-supervisor.git $@

# Checkout git based dependencies.
checkouts: $(prefix)/supervisor

build: depends checkouts

check:
	@puppet parser --verbose validate $(manifests) && \
		echo 'All manifests parsed without error.'

lint:
	@for f in $(manifests); do \
		echo "\nLinting $$f ..." && bundle exec puppet-lint $$f; \
	done
