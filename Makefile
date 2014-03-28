#!/usr/bin/make

PNAME    		= kvmtool
PDESC    		= kvmtool - automatically create and wipe kvm domains, add salt to domains

REPOSITORY 		= deb.mawoh.org
REPODIR 		= /var/www/deb.mawoh.org/web
REPONAME		= mawoh

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
	@echo ""
	@echo "This is the Makefile for $(PNAME) $(DEBVERSION)"
	@echo ""
	@echo "help     this help"
	@echo "version  shows version of $(PNAME) taken from debian/changelog"
	@echo "release  starts workflow to increase version number, create a debian package, and create a git release"
	@echo ""
	@echo "clean    removes tmp/cache files"
	@echo "upload   upload .deb packages to remote debian repo and update reprepo"
	@echo "package  create debian package"
	@echo ""


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
	@mv -v ../$(PNAME)_* ../packages || true
	@echo ""
	@echo ""
	@echo "latest package:"
	@ls -lrt ../packages/$(PNAME)_*.deb|tail -n1

release: set-debian-release
set-debian-release:
	@if ! git branch --no-color |grep -q '\* develop$$'; then echo "not in branch develop. merge your changes to develop and try again."; exit 1; fi
	@if [ -n "$$(git status -s|grep -vE '^\?')" ]; then echo "there a uncommitted changes. aborting"; exit 1; fi
	@if [ -n "$$(git status -s)" ]; then git status -s;echo;echo "there are new files. press CTRL-c to abort or ENTER to continue"; read; fi
	@echo -n "current " && dpkg-parsechangelog|grep Version:
	@nv=$$(echo "$(DEBVERSION)" | perl -ne '/^(.*)\.(\d+)/ or die; $$b=$$2+1; print "$$1.$$b"') && \
		echo "enter new version number or press CTRL-c to abort" && \
		echo -n "new version [$$nv]: " && \
		read -ei "$$nv" v && \
		[ -n "$$v" ] || v="$$nv" && \
		echo "ok, new version will be $$v" && \
		NEWVERSION="$$v" make bump

bump:
	@if [ -z "$(NEWVERSION)" ]; then echo "need NEWVERSION env var";exit 1;fi
	@echo "starting release $(NEWVERSION)"
	git flow release start "$(NEWVERSION)"
	dch  --force-distribution -D stable -v "$(NEWVERSION)" "new release" 2>/dev/null
	@echo -n "Debian new ";dpkg-parsechangelog|grep Version:
	@echo "now run at least the following commands:"
	@echo "# make package"
	@echo "# git commit -av"
	@echo "# git flow release finish $(NEWVERSION)"
	@echo "# git push"
	@echo "# git push --tags"

version: status
status:
	@echo "this is $(PNAME) $(DEBVERSION) build $(BUILD)"

upload: move-packages
	rsync -vP ../packages/$(PNAME)_$(DEBVERSION)_*.deb root@$(REPOSITORY):/tmp/ 
	ssh -l root $(REPOSITORY) 'cd $(REPODIR) && for f in /tmp/*deb; do reprepro includedeb $(REPONAME) $$f && rm -v $$f;done'


