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
	@echo "no tests available"


update-doc:
	echo "no docs"

install: clean update-doc 
	@echo "installing $(PNAME) $(VERSION).$(RELEASE)-$(REVISION)"
	mkdir -p $(INST_BINDIR)
	mkdir -p $(INST_SBINDIR)
	mkdir -p $(INST_ETCDIR)
	mkdir -p $(INST_ETCDIR)/preseeds
	#
	# binaries
	install -g root -o root -m 755 bin/kvmtool $(INST_SBINDIR)/
	perl -p -i -e "s/^VERSION=noversion/VERSION='$(VERSION).$(RELEASE)-$(REVISION)'/" $(INST_SBINDIR)/kvmtool
	#
	# configuration
	cp -a etc/preseeds/*default*.cfg $(INST_ETCDIR)/preseeds
	cp -a etc/*.sh $(INST_ETCDIR)/
	cp -a etc/authorized_keys $(INST_ETCDIR)/
	chown -vR root:root $(INST_ETCDIR)/
	chmod -vR u=Xrw,go= $(INST_ETCDIR)/

package: debian-package
debian-package: set-debian-release
	hg commit
	hg tag "$(VERSION).$(RELEASE)-$(REVISION)"	
	make changelog
	hg commit -m "package build $(VERSION).$(RELEASE)-$(REVISION)"
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
	@(mv -v ../$(PNAME)_*.*1-*.* ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*3-*.* ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*5-*.* ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*7-*.* ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.*9-*.* ../unstable 2>&1|grep -v 'cannot stat') || true
	@(mv -v ../$(PNAME)_*.* ../stable 2>&1|grep -v 'cannot stat') || true

upload: move-packages
	rsync -vP ../stable/*deb root@$(REPOSITORY):/tmp/ 
	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb squeeze $$f;done'


changelog:
	 hg history --style changelog >CHANGELOG
