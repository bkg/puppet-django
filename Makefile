prefix ?= $(HOME)/.puppet/modules

deps = $(shell awk '/^dependency/ {print $$2$$3}' Modulefile)
repos = https://github.com/puppetmodules/puppet-module-python.git

all: build

depends:
	@for dep in $(deps); do \
		pkgname="$${dep%%,*}"; \
		[ -d $(prefix)/$${pkgname##*/} ] || \
			puppet module install "$$pkgname" --version "$${dep##*,}" --modulepath $(prefix); \
	done

$(prefix)/python:
	git clone $(firstword $(repos)) $@

checkouts: $(prefix)/python

build: depends checkouts

check:
	puppet parser --verbose validate $$(find . -name '*.pp')
