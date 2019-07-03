include /usr/share/dpkg/pkg-info.mk

PACKAGE := pve-libseccomp-dev

ARCH := $(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION := $(shell git rev-parse HEAD)

SRCDIR=libseccomp
BUILDSRC := $(PACKAGE)-$(DEB_VERSION_UPSTREAM)

DEB := pve-libseccomp2.4-dev_$(DEB_VERSION_UPSTREAM_REVISION)_$(ARCH).deb

all: $(DEB)
	echo $(DEB)

.PHONY: submodule
submodule:
	test -f "$(SRCDIR)/confiure.ac" || git submodule update --init

$(BUILDSRC): libseccomp debian | submodule
	rm -rf $(BUILDSRC)
	cp -a $(SRCDIR) $(BUILDSRC)
	cp -a debian $(BUILDSRC)/debian
	echo "git clone git://git.proxmox.com/git/pve-libseccomp.git\\ngit checkout ${GITVERSION}" >$(BUILDSRC)/debian/SOURCE

.PHONY: deb
deb: $(DEB)
$(DEB): $(BUILDSRC)
	rm -f *.deb
	cd $(BUILDSRC); dpkg-buildpackage -b -us -uc
	lintian $(DEB)

.PHONY: dsc
dsc: $(DSC)
$(DSC): $(BUILDSRC)
	rm -f *.dsc
	cd $(BUILDSRC); dpkg-buildpackage -S -us -uc -d -nc
	lintian $(DSC)

.PHONY: upload
upload: $(DEB)
	tar cf - $(DEB) | ssh repoman@repo.proxmox.com upload --product pve --dist stretch

.PHONY: clean
clean:
	rm -rf $(BUILDSRC) *.deb *.tar.gz *.changes *.dsc *.buildinfo

.PHONY: dinstall
dinstall: $(DEB)
	dpkg -i $(DEB)
