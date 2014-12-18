NODE_ENV ?= production

DESTDIR := $(PWD)/system
TMP     := $(PWD)/.tmp
DEP     := $(TMP)/deps

OS   := $(shell uname)
ARCH := $(shell uname -m)

ENT_BUCKET ?= web-core
ENT_SERVER := ent.int.s-cloud.net
ENT_BASE   := $(ENT_SERVER)/$(ENT_BUCKET)

NODE_VERSION := 0.10.31
NODE         := nodejs-$(NODE_VERSION)
NODE_BIN     := $(DESTDIR)/usr/bin/node
NPM_BIN      := $(DESTDIR)/usr/bin/npm

#############

.PHONY: all build

all: build

build: $(NODE_BIN) node_modules .env
	PATH=$(DESTDIR)/usr/bin:$(PATH) ./kiwi build

.env: .env.dev
ifeq ($(NODE_ENV), development)
	cp $< $@
endif

#############

$(NODE_BIN): $(DESTDIR)/usr/lib/$(NODE)/bin/node
	mkdir -p $(@D)
	@# symlink all the binaries into system/usr/bin
	ln -s $(<D)/* $(@D)

$(NPM_BIN): $(NODE_BIN)

$(DESTDIR)/usr/lib/$(NODE)/bin/node: $(DEP)/node/$(OS)/$(NODE_VERSION).tar.gz
	mkdir -p $(@D)
	tar xzv -C $(DESTDIR)/usr/lib/$(NODE) --strip-components 1 -f $<
	touch $@

node_modules: $(NPM_BIN) package.json
	PATH=$(DESTDIR)/usr/bin:$(PATH) HOME=$${PWD} $(NPM_BIN) install $(NPM_OPTIONS)
	rm -f node_modules/shared
	ln -s ../app/shared node_modules/shared

$(DEP)/%:
	curl -q $(CURL_OPTIONS) --create-dirs --fail --location $(ENT_BASE)/$(subst $(DEP)/,,$@) --output $@
	touch $@
