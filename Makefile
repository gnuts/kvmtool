#!/usr/bin/make

PNAME    		= kvmtool
PDESC    		= kvmtool - automatically create and wipe kvm domains, add salt to domains

REPOSITORY 		= ispconfig.mawoh.org
REPODIR 		= /var/www/clients/client1/web22/web

DESTDIR 		?= /
USRPREFIX  		?= /usr
BUILD    		= $(shell git log --pretty=format:'' | wc -l)
DEBVERSION 		= $(shell dpkg-parsechangelog|grep Version:|cut -d" " -f2-)

BINDIR  		= $(USRPREFIX)/bin
SBINDIR 		= $(USRPREFIX)/sbin
LIBDIR  		= $(USRPREFIX)/lib/$(PNAME)
VARLIBDIR  		= /var/lib/$(PNAME)
USRSHAREDIR 	= /usr/share/$(PNAME)
ETCDIR			= /etc/$(PNAME)
RULESDIR		= /lib/udev/rules.d

INST_BINDIR		= $(DESTDIR)/$(BINDIR)
INST_SBINDIR  	= $(DESTDIR)/$(SBINDIR)
INST_LIBDIR   	= $(DESTDIR)/$(LIBDIR)
INST_VARLIBDIR	= $(DESTDIR)/$(VARLIBDIR)
INST_USRSHAREDIR= $(DESTDIR)/$(USRSHAREDIR)
INST_ETCDIR   	= $(DESTDIR)/$(ETCDIR)
INST_RULESDIR 	= $(DESTDIR)/$(RULESDIR)

SHELL	 		= /bin/bash



help:
	@echo "make version		shows version of program"
	@echo "make clean		removes tmp/cache files"
	@echo "make upload		upload .deb packages to remote debian repo and update reprepo"
	@echo "make package		create debian package"
	@echo "make bump		update debian changelog. use once when in release branch"
	@echo ""
	@echo ""
	@echo "more functions:"
	@echo "make increase-revision	increment the third element of the version number"
	@echo "make reset-revision		reset the third element of the version number to 1"
	@echo "make increase-release	increment the second element of the version number"
	@echo ""
	@echo ""
	@echo "when creating a new release:"



build: update-version

clean:
	rm -f *~
	rm -f *.8
	rm -f *.1
	rm -f debian/cron.d
	rm -rf itmp
	rm -rf mtmp
	rm -rf debian/$(PNAME)


test:
	@echo "no tests available"


update-doc:
	echo "no docs"

install: clean update-doc 
	@echo "installing $(PNAME) $(DEBVERSION) build $(BUILD)"
	#
	# create directories
	#
	mkdir -p $(INST_BINDIR)
	mkdir -p $(INST_SBINDIR)
	mkdir -p $(INST_USRSHAREDIR)
	mkdir -p $(INST_ETCDIR)
	mkdir -p $(INST_ETCDIR)/preseeds
	#
	# binaries
	#
	install -g root -o root -m 755 bin/kvmtool $(INST_SBINDIR)/
	perl -p -i -e "s/^VERSION=noversion/VERSION='$(DEBVERSION)'/" $(INST_SBINDIR)/kvmtool
	#
	# configuration
	#
	cp -a etc/preseeds/*default*.cfg $(INST_ETCDIR)/preseeds
	cp -a etc/*.sh $(INST_ETCDIR)/
	cp -a etc/authorized_keys $(INST_ETCDIR)/
	chown -vR root:root $(INST_ETCDIR)/
	chmod -vR u=Xrw,go= $(INST_ETCDIR)/
	#
	# support files
	#
	install -o root -g root -m 644 share/default.template    $(INST_USRSHAREDIR)
	install -o root -g root -m 644 share/salt-script.wheezy  $(INST_USRSHAREDIR)
	install -o root -g root -m 644 share/salt-script.squeeze $(INST_USRSHAREDIR)
	install -o root -g root -m 644 share/salt-script.ubuntu  $(INST_USRSHAREDIR)


package: debian-package move-packages
debian-package:
	debuild --no-tgz-check -uc -us

move-packages:
	@mkdir -p ../packages
	@mv -v ../$(PNAME)_* ../packages
	@echo ""
	@echo ""
	@echo "latest package:"
	@ls -lrt ../packages/*.deb|tail -n1

bump: set-debian-release
set-debian-release:
	@if [ -n "$$(git status -s|grep -vE '^\?')" ]; then echo "there a uncommitted changes. aborting"; exit 1; fi
	@if [ -n "$$(git status -s)" ]; then echo "there are new files. press CTRL-c to abort or ENTER to continue"; read; fi
	@echo -n "current " && dpkg-parsechangelog|grep Version:
	@nv=$$(echo "$(DEBVERSION)" | perl -ne '/^(.*)\.(\d+)/ or die; $$b=$$2+1; print "$$1.$$b"') && \
		echo "enter new version number or press CTRL-c to abort" && \
		echo -n "new version [$$nv]: " && \
		read -ei "$$nv" v && \
		[ -n "$$v" ] || v="$$nv" && \
		echo "ok, new version will be $$v" && \
		NEWVERSION="$$v" make release

release:
	@if [ -z "$(NEWVERSION)" ]; then echo "need NEWVERSION env var";exit 1;fi
	@echo "starting release $(NEWVERSION)"
	git flow release start "$(NEWVERSION)"
	dch  --force-distribution -D stable -v "$(NEWVERSION)" "new release" 2>/dev/null
	@echo -n "Debian new ";dpkg-parsechangelog|grep Version:
	@echo "now run at least the following commands:"
	@echo "# make package"
	@echo "# git commit -av"
	@echo "# git flow release finish"
	@echo "# git push"
	@echo "# git push --tags"

version: status
status:
	@echo "this is $(PNAME) $(DEBVERSION) build $(BUILD)"

#upload: move-packages
#	rsync -vP ../stable/*deb root@$(REPOSITORY):/tmp/ 
#	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb squeeze $$f;done'
#

