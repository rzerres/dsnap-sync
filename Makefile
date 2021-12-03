# dsnap-sync
# https://github.com/rzerres/dsnap-sync
# Copyright (C) 2016, 2017 James W. Barnett
# Copyright (C) 2017 - 2021 Ralf Zerres

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,

PKGNAME = dsnap-sync
PREFIX ?= /usr
SNAPPER_CONFIG ?= /etc/default/snapper
SNAPPER_TEMPLATES ?= /etc/snapper/config-templates
DSNAP_SYNC_EXAMPLES = usr/share/doc/dsnap-sync

BIN_DIR = $(DESTDIR)$(PREFIX)/bin
ETC_DIR = $(DESTDIR)/etc
SYSTEMD_DIR = $(DESTDIR)$(PREFIX)/lib/systemd/system
DOC_DIR = $(DESTDIR)$(PREFIX)/share/doc/dsnap-sync

.PHONY: install

install:
	@./find_snapper_config || sed -i 's@^SNAPPER_CONFIG=.*@SNAPPER_CONFIG='$(SNAPPER_CONFIG)'@g' bin/$(PKGNAME)
	@install -Dm755 bin/* -t $(BIN_DIR)/
	@install -dm755 $(ETC_DIR)/dsnap-sync
	@install -Dm644 etc/dsnap-sync/* -t $(ETC_DIR)/dsnap-sync/
	@install -dm755 $(ETC_DIR)/snapper/config-templates
	@install -Dm644 etc/snapper/config-templates/* -t $(ETC_DIR)/snapper/config-templates/
	@install -Dm644 $(DSNAP_SYNC_EXAMPLES)/* -t $(DOC_DIR)/
