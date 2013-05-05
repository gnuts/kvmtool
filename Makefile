SHELL	 = /bin/bash

#
# 
#
PNAME    = kvmtool
PDESC    = kvmtool - automatically create and wipe kvm domains, add salt to domains
REPOSITORY = ispconfig.mawoh.org
REPODIR = /var/www/clients/client1/web22/web

DESTDIR ?= /
USRPREFIX  ?= /usr
VERSION  = $(shell head -n 1 VERSION)
RELEASE  = $(shell head -n 1 RELEASE)
REVISION = $(shell hg parents|grep changeset:|tr -d " "|cut -d: -f2)
USER     = $(shell hg parents|grep "user:"|perl -pe 's/user:\s*//')

BINDIR  = $(USRPREFIX)/bin
SBINDIR = $(USRPREFIX)/sbin
LIBDIR  = $(USRPREFIX)/lib/$(PNAME)
VARLIBDIR  = /var/lib/$(PNAME)
ETCDIR  = /etc/$(PNAME)

INST_BINDIR   = $(DESTDIR)/$(BINDIR)
INST_SBINDIR  = $(DESTDIR)/$(SBINDIR)
INST_LIBDIR   = $(DESTDIR)/$(LIBDIR)
INST_VARLIBDIR= $(DESTDIR)/$(VARLIBDIR)
INST_ETCDIR   = $(DESTDIR)/$(ETCDIR)


help:
	@echo "use the source - or add documentation"

build: update-version

clean:
	rm -f *~
	rm -f *.8
	rm -f *.1
	rm -f debian/cron.d
	rm -rf itmp
	rm -rf mtmp


test:
	@perl -wc bin/kvmtool


update-doc:
	echo "no docs"

install: clean update-doc
	@echo "installing $(PNAME) $(VERSION).$(RELEASE)-$(REVISION)"
	mkdir -p $(INST_BINDIR)
	mkdir -p $(INST_SBINDIR)
	mkdir -p $(INST_ETCDIR)
	# binaries
	install -g root -o root -m 755 bin/kvmtool $(INST_SBINDIR)/
	# configuration
	cp etc/vpn-ca4.conf.example $(INST_ETCDIR)/vpn-ca4.conf
	cp etc/openssl.cnf $(INST_ETCDIR)/
	cp etc/*.example $(INST_ETCDIR)/
	cp ssl/*.example $(INST_VARLIBDIR)/ssl/
	chown -vR root:root $(INST_ETCDIR)/
	chmod -vR u=Xrw,go= $(INST_ETCDIR)/
	chown -vR root:root $(INST_VARLIBDIR)/
	chmod -vR u=Xrw,go= $(INST_VARLIBDIR)/

package: debian-package
debian-package: set-debian-release
	hg tag "$(VERSION).$(RELEASE)-$(REVISION)"	
	make changelog
	dpkg-buildpackage -ai386 -rfakeroot -us -uc
	dpkg-buildpackage -aamd64 -rfakeroot -us -uc
	make move-packages
	@ls -1rt ../stable/*i386*deb|tail -n 1
	@ls -1rt ../stable/*amd64*deb|tail -n 1
	@ls -1rt ../unstable/*i386*deb|tail -n 1
	@ls -1rt ../unstable/*amd64*deb|tail -n 1

set-debian-release:
	DEBEMAIL="$(USER)" dch -v "$(VERSION).$(RELEASE)-$(REVISION)" "new release"

increase-release:
	@cat RELEASE|perl -pe '$$_++' >RELEASE.new
	@mv RELEASE.new RELEASE
	make version

update-version-files:
	@head -n 1 debian/changelog | \
	perl -ne '/\(([\d\.]+)\.(\d+)\-(\d+)\)/ and print "$$1\n"' >VERSION
	@head -n 1 debian/changelog | \
	perl -ne '/\(([\d\.]+)\.(\d+)\-(\d+)\)/ and print "$$2\n"' >RELEASE

version: status
status:
	@echo "this is $(PNAME) $(VERSION).$(RELEASE)-$(REVISION)"

new-release:
	@echo "are you sure you want to increase the release number $(RELEASE)?"
	@echo "press ENTER to continue or C-c to abort"
	@read
	make increase-release set-debian-release update-version-files
	hg commit
	hg tag "$(VERSION).$(RELEASE)"	
	hg push

devlinks:
	ln -svf $$(pwd)/bin/vpn-ca4 $(SBINDIR)/

devupdate: reinstall devlinks

move-packages:
	@mkdir -p ../stable ../unstable
	@(mv -v ../$(PNAME)_*.*1-*_*.deb ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*3-*_*.deb ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*5-*_*.deb ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*7-*_*.deb ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*9-*_*.deb ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*1-*_*.changes ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*3-*_*.changes ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*5-*_*.changes ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*7-*_*.changes ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*9-*_*.changes ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*1-*_*.tar.gz ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*3-*_*.tar.gz ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*5-*_*.tar.gz ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*7-*_*.tar.gz ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*9-*_*.tar.gz ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*1-*_*.dsc ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*3-*_*.dsc ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*5-*_*.dsc ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*7-*_*.dsc ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.*9-*_*.dsc ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.deb ../stable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.dsc ../stable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.changes ../stable 2>&1|grep -v 'cannot stat') || true
	@(mv ../$(PNAME)_*.tar.gz ../stable 2>&1|grep -v 'cannot stat') || true


upload: move-packages
	rsync -vP ../stable/*deb root@$(REPOSITORY):/tmp/ 
	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb squeeze $$f;done'


changelog:
	 hg history --style changelog >CHANGELOG
