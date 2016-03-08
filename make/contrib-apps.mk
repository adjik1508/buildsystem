#
# busybox
#
BUSYBOX_VER = 1.24.1

$(ARCHIVE)/busybox-$(BUSYBOX_VER).tar.bz2:
	$(WGET) http://busybox.net/downloads/busybox-$(BUSYBOX_VER).tar.bz2

$(D)/busybox: $(D)/bootstrap $(ARCHIVE)/busybox-$(BUSYBOX_VER).tar.bz2 $(PATCHES)/busybox.config$(if $(UFS912)$(UFS913)$(SPARK)$(SPARK7162),_nandwrite)
	rm -fr $(BUILD_TMP)/busybox-$(BUSYBOX_VER)
	$(UNTAR)/busybox-$(BUSYBOX_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/busybox-$(BUSYBOX_VER); \
		$(PATCH)/busybox-1.24.1-ifupdown.patch; \
		$(PATCH)/busybox-1.24.1-unicode.patch; \
		$(PATCH)/busybox-1.24.1-extra.patch; \
		install -m 0644 $(lastword $^) .config; \
		sed -i -e 's#^CONFIG_PREFIX.*#CONFIG_PREFIX="$(TARGETPREFIX)"#' .config; \
		$(BUILDENV) $(MAKE) busybox CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)"; \
		$(MAKE) install CROSS_COMPILE=$(TARGET)- CFLAGS_EXTRA="$(TARGET_CFLAGS)" CONFIG_PREFIX=$(TARGETPREFIX)
#	$(REMOVE)/busybox-$(BUSYBOX_VER)
	touch $@

#
# host_pkgconfig
#
PKGCONFIG_VER = 0.29

$(ARCHIVE)/pkg-config-$(PKGCONFIG_VER).tar.gz:
	$(WGET) http://pkgconfig.freedesktop.org/releases/pkg-config-$(PKGCONFIG_VER).tar.gz

$(D)/host_pkgconfig: $(ARCHIVE)/pkg-config-$(PKGCONFIG_VER).tar.gz
	$(REMOVE)/pkg-config-$(PKGCONFIG_VER)
	$(UNTAR)/pkg-config-$(PKGCONFIG_VER).tar.gz
	set -e; cd $(BUILD_TMP)/pkg-config-$(PKGCONFIG_VER); \
		./configure \
			--prefix=$(HOSTPREFIX) \
			--program-prefix=$(TARGET)- \
			--disable-host-tool \
			--with-pc_path=$(TARGETPREFIX)/usr/lib/pkgconfig \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/pkg-config-$(PKGCONFIG_VER)
	touch $@

#
# host_mtd_utils
#
MTD_UTILS_VER = 1.5.2

$(ARCHIVE)/mtd-utils-$(MTD_UTILS_VER).tar.bz2:
	$(WGET) ftp://ftp.infradead.org/pub/mtd-utils/mtd-utils-$(MTD_UTILS_VER).tar.bz2

$(D)/host_mtd_utils: $(ARCHIVE)/mtd-utils-$(MTD_UTILS_VER).tar.bz2
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(UNTAR)/mtd-utils-$(MTD_UTILS_VER).tar.bz2; \
	set -e; cd $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER); \
		$(PATCH)/host-mtd-utils-1.5.2.patch; \
		$(MAKE) `pwd`/mkfs.jffs2 `pwd`/sumtool BUILDDIR=`pwd` WITHOUT_XATTR=1 DESTDIR=$(HOSTPREFIX); \
		$(MAKE) install DESTDIR=$(HOSTPREFIX)/bin
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	touch $@

#
# mtd_utils
#
$(D)/mtd_utils: $(D)/bootstrap $(D)/zlib $(D)/lzo $(D)/e2fsprogs $(ARCHIVE)/mtd-utils-$(MTD_UTILS_VER).tar.bz2
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	$(UNTAR)/mtd-utils-$(MTD_UTILS_VER).tar.bz2 ; \
	set -e; cd $(BUILD_TMP)/mtd-utils-$(MTD_UTILS_VER); \
		$(BUILDENV) \
		$(MAKE) PREFIX= CC=$(TARGET)-gcc LD=$(TARGET)-ld STRIP=$(TARGET)-strip WITHOUT_XATTR=1 DESTDIR=$(TARGETPREFIX); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/mtd-utils-$(MTD_UTILS_VER)
	touch $@

#
# opkg
#
OPKG_VER = 0.2.2

$(ARCHIVE)/opkg-$(OPKG_VER).tar.gz:
	$(WGET) http://git.yoctoproject.org/cgit/cgit.cgi/opkg/snapshot/opkg-$(OPKG_VER).tar.gz

$(D)/opkg-host: $(ARCHIVE)/opkg-$(OPKG_VER).tar.gz
	$(REMOVE)/opkg-$(OPKG_VER)
	$(UNTAR)/opkg-$(OPKG_VER).tar.gz
	set -e; cd $(BUILD_TMP)/opkg-$(OPKG_VER); \
		autoreconf -v --install; \
		./configure \
			--prefix= \
			--disable-gpg \
			--disable-shared \
		; \
		$(MAKE) all; \
		cp -a src/opkg-cl $(HOSTPREFIX)/bin
	$(REMOVE)/opkg-$(OPKG_VER)
	touch $@

$(D)/opkg: $(D)/bootstrap $(D)/opkg-host $(D)/libcurl $(ARCHIVE)/opkg-$(OPKG_VER).tar.gz
	$(REMOVE)/opkg-$(OPKG_VER)
	$(UNTAR)/opkg-$(OPKG_VER).tar.gz
	set -e; cd $(BUILD_TMP)/opkg-$(OPKG_VER); \
		$(PATCH)/opkg-0.2.0-dont-segfault.patch; \
		autoreconf -v --install; \
		echo ac_cv_func_realloc_0_nonnull=yes >> config.cache; \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-gpg \
			--config-cache \
			--mandir=/.remove \
		; \
		$(MAKE) all ; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	install -d -m 0755 $(TARGETPREFIX)/var/lib/opkg
	install -d -m 0755 $(TARGETPREFIX)/etc/opkg
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libopkg.pc
	$(REMOVE)/opkg-$(OPKG_VER)
	touch $@

#
# sysvinit
#
SYSVINIT_VER = 2.88dsf

$(ARCHIVE)/sysvinit_$(SYSVINIT_VER).orig.tar.gz:
	$(WGET) ftp://ftp.debian.org/debian/pool/main/s/sysvinit/sysvinit_$(SYSVINIT_VER).orig.tar.gz

$(D)/sysvinit: $(D)/bootstrap $(ARCHIVE)/sysvinit_$(SYSVINIT_VER).orig.tar.gz
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	$(UNTAR)/sysvinit_$(SYSVINIT_VER).orig.tar.gz
	set -e; cd $(BUILD_TMP)/sysvinit-$(SYSVINIT_VER); \
		sed -i -e 's/\ sulogin[^ ]*//' -e 's/pidof\.8//' -e '/ln .*pidof/d' \
		-e '/bootlogd/d' -e '/utmpdump/d' -e '/mountpoint/d' -e '/mesg/d' src/Makefile; \
		$(BUILDENV) \
		$(MAKE) -C src SULOGINLIBS=-lcrypt; \
		$(MAKE) install ROOT=$(TARGETPREFIX) MANDIR=/.remove
ifeq ($(BOXTYPE), $(filter $(BOXTYPE), fortis_hdbox octagon1008 cuberevo cuberevo_mini2 cuberevo_2000hd))
	install -m 644 $(SKEL_ROOT)/etc/inittab_ttyAS1 $(TARGETPREFIX)/etc/inittab
else
	install -m 644 $(SKEL_ROOT)/etc/inittab $(TARGETPREFIX)/etc/inittab
endif
	$(REMOVE)/sysvinit-$(SYSVINIT_VER)
	touch $@

#
# host_module_init_tools
#
MODULE_INIT_TOOLS_VER = 3.16

$(ARCHIVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2:
	$(WGET) http://ftp.be.debian.org/pub/linux/utils/kernel/module-init-tools/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2

$(D)/host_module_init_tools: $(ARCHIVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(UNTAR)/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/module-init-tools-$(MODULE_INIT_TOOLS_VER); \
		$(PATCH)/module-init-tools-3.16.patch; \
		autoreconf -fi; \
		./configure \
			--prefix=$(HOSTPREFIX) \
			--sbindir=$(HOSTPREFIX)/bin \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	touch $@

#
# module_init_tools
#
$(D)/module_init_tools: $(D)/bootstrap $(D)/lsb  $(ARCHIVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	$(UNTAR)/module-init-tools-$(MODULE_INIT_TOOLS_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/module-init-tools-$(MODULE_INIT_TOOLS_VER); \
		$(PATCH)/module-init-tools-3.16.patch; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix= \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-builddir \
		; \
		$(MAKE); \
		$(MAKE) install sbin_PROGRAMS="depmod modinfo" bin_PROGRAMS= DESTDIR=$(TARGETPREFIX)
	$(call adapted-etc-files,$(MODULE_INIT_TOOLS_ADAPTED_ETC_FILES))
	$(REMOVE)/module-init-tools-$(MODULE_INIT_TOOLS_VER)
	touch $@

#
# lsb
#
LSB_MAJOR = 3.2
LSB_MINOR = 20
LSB_VER = $(LSB_MAJOR)-$(LSB_MINOR)

$(ARCHIVE)/lsb_$(LSB_VER)$(LSB_SUBVER).tar.gz:
	$(WGET) http://debian.sdinet.de/etch/sdinet/lsb/lsb_$(LSB_VER).tar.gz

$(D)/lsb: $(D)/bootstrap $(ARCHIVE)/lsb_$(LSB_VER).tar.gz
	$(REMOVE)/lsb-$(LSB_MAJOR)
	$(UNTAR)/lsb_$(LSB_VER).tar.gz
	set -e; cd $(BUILD_TMP)/lsb-$(LSB_MAJOR); \
		install -m 0644 init-functions $(TARGETPREFIX)/lib/lsb
	$(REMOVE)/lsb-$(LSB_MAJOR)
	touch $@

#
# portmap
#
PORTMAP_VER = 6.0.0

$(ARCHIVE)/portmap_$(PORTMAP_VER).orig.tar.gz:
	$(WGET) https://merges.ubuntu.com/p/portmap/portmap_$(PORTMAP_VER).orig.tar.gz

$(ARCHIVE)/portmap_$(PORTMAP_VER)-2.diff.gz:
	$(WGET) https://merges.ubuntu.com/p/portmap/portmap_$(PORTMAP_VER)-2.diff.gz

$(D)/portmap: $(D)/bootstrap $(ARCHIVE)/portmap_$(PORTMAP_VER).orig.tar.gz $(ARCHIVE)/portmap_$(PORTMAP_VER)-2.diff.gz
	$(REMOVE)/portmap-$(PORTMAP_VER)
	$(UNTAR)/portmap_$(PORTMAP_VER).orig.tar.gz
	set -e; cd $(BUILD_TMP)/portmap-$(PORTMAP_VER); \
		gunzip -cd $(lastword $^) | cat > debian.patch; \
		patch -p1 <debian.patch && \
		sed -e 's/### BEGIN INIT INFO/# chkconfig: S 41 10\n### BEGIN INIT INFO/g' -i debian/init.d; \
		$(PATCH)/portmap-6.0.patch; \
		$(BUILDENV) $(MAKE) NO_TCP_WRAPPER=1 DAEMON_UID=65534 DAEMON_GID=65535 CC="$(TARGET)-gcc"; \
		install -m 0755 portmap $(TARGETPREFIX)/sbin; \
		install -m 0755 pmap_dump $(TARGETPREFIX)/sbin; \
		install -m 0755 pmap_set $(TARGETPREFIX)/sbin; \
		install -m755 debian/init.d $(TARGETPREFIX)/etc/init.d/portmap
	$(REMOVE)/portmap-$(PORTMAP_VER)
	touch $@

#
# e2fsprogs
#
E2FSPROGS_VER = 1.42.13

$(ARCHIVE)/e2fsprogs-$(E2FSPROGS_VER).tar.gz:
	$(WGET) http://sourceforge.net/projects/e2fsprogs/files/e2fsprogs/v$(E2FSPROGS_VER)/e2fsprogs-$(E2FSPROGS_VER).tar.gz

$(D)/e2fsprogs: $(D)/bootstrap $(D)/utillinux $(ARCHIVE)/e2fsprogs-$(E2FSPROGS_VER).tar.gz
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	$(UNTAR)/e2fsprogs-$(E2FSPROGS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER); \
		$(PATCH)/e2fsprogs-1.42.13.patch; \
		PATH=$(BUILD_TMP)/e2fsprogs-$(E2FSPROGS_VER):$(PATH) \
		$(CONFIGURE) \
			--prefix=/usr \
			--libdir=/usr/lib \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-rpath \
			--disable-quota \
			--disable-testio-debug \
			--disable-defrag \
			--disable-nls \
			--disable-jbd-debug \
			--disable-blkid-debug \
			--disable-testio-debug \
			--disable-debugfs \
			--disable-imager \
			--disable-resizer \
			--enable-elf-shlibs \
			--enable-fsck \
			--enable-verbose-makecmds \
			--enable-symlink-install \
			--without-libintl-prefix \
			--without-libiconv-prefix \
			--with-root-prefix="" \
			; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX); \
		$(MAKE) -C lib/uuid  install DESTDIR=$(TARGETPREFIX); \
		$(MAKE) -C lib/blkid install DESTDIR=$(TARGETPREFIX); \
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/uuid.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/blkid.pc
	cd $(TARGETPREFIX) && rm sbin/badblocks sbin/dumpe2fs sbin/logsave \
				 sbin/e2undo usr/sbin/filefrag usr/sbin/e2freefrag \
				 usr/bin/chattr usr/bin/lsattr usr/bin/uuidgen
	$(REMOVE)/e2fsprogs-$(E2FSPROGS_VER)
	touch $@

#
# jfsutils
#
JFSUTILS_VER = 1.1.15

$(ARCHIVE)/jfsutils-$(JFSUTILS_VER).tar.gz:
	$(WGET) http://jfs.sourceforge.net/project/pub/jfsutils-$(JFSUTILS_VER).tar.gz

$(D)/jfsutils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/jfsutils-$(JFSUTILS_VER).tar.gz
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	$(UNTAR)/jfsutils-$(JFSUTILS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/jfsutils-$(JFSUTILS_VER); \
		$(PATCH)/jfsutils-1.1.15.patch; \
		sed "s@<unistd.h>@&\n#include <sys/types.h>@g" -i fscklog/extract.c; \
		autoreconf -fi; \
		$(CONFIGURE) \
			--prefix= \
			--target=$(TARGET) \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	cd $(TARGETPREFIX) && rm sbin/jfs_debugfs sbin/jfs_fscklog sbin/jfs_logdump
	$(REMOVE)/jfsutils-$(JFSUTILS_VER)
	touch $@

#
# utillinux
#
UTIL_LINUX_MAJOR = 2.25
UTIL_LINUX_MINOR = 2
UTIL_LINUX_VER = $(UTIL_LINUX_MAJOR).$(UTIL_LINUX_MINOR)

$(ARCHIVE)/util-linux-$(UTIL_LINUX_VER).tar.xz:
	$(WGET) http://ftp.kernel.org/pub/linux/utils/util-linux/v$(UTIL_LINUX_MAJOR)/util-linux-$(UTIL_LINUX_VER).tar.xz

$(D)/utillinux: $(D)/bootstrap $(D)/zlib $(ARCHIVE)/util-linux-$(UTIL_LINUX_VER).tar.xz
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	$(UNTAR)/util-linux-$(UTIL_LINUX_VER).tar.xz
	set -e; cd $(BUILD_TMP)/util-linux-$(UTIL_LINUX_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--disable-static \
			--disable-gtk-doc \
			--disable-nls \
			--disable-rpath \
			--disable-libuuid \
			--disable-libblkid \
			--disable-libmount \
			--disable-libsmartcols \
			--disable-mount \
			--disable-partx \
			--disable-mountpoint \
			--disable-fallocate \
			--disable-unshare \
			--disable-nsenter \
			--disable-setpriv \
			--disable-eject \
			--disable-agetty \
			--disable-cramfs \
			--disable-bfs \
			--disable-minix \
			--disable-fdformat \
			--disable-hwclock \
			--disable-wdctl \
			--disable-switch_root \
			--disable-pivot_root \
			--enable-tunelp \
			--disable-kill \
			--disable-last \
			--disable-utmpdump \
			--disable-line \
			--disable-mesg \
			--disable-raw \
			--disable-rename \
			--disable-reset \
			--disable-vipw \
			--disable-newgrp \
			--disable-chfn-chsh \
			--disable-login \
			--disable-login-chown-vcs \
			--disable-login-stat-mail \
			--disable-nologin \
			--disable-sulogin \
			--disable-su \
			--disable-runuser \
			--disable-ul \
			--disable-more \
			--disable-pg \
			--disable-setterm \
			--disable-schedutils \
			--disable-tunelp \
			--disable-wall \
			--disable-write \
			--disable-bash-completion \
			--disable-pylibmount \
			--disable-pg-bell \
			--disable-use-tty-group \
			--disable-makeinstall-chown \
			--disable-makeinstall-setuid \
			--without-audit \
			--without-ncurses \
			--without-slang \
			--without-utempter \
			--disable-wall \
			--without-python \
			--disable-makeinstall-chown \
			--without-systemdsystemunitdir \
			; \
		$(MAKE); \
		install -D -m 755 sfdisk $(TARGETPREFIX)/sbin/sfdisk; \
		install -D -m 755 mkfs $(TARGETPREFIX)/sbin/mkfs
	$(REMOVE)/util-linux-$(UTIL_LINUX_VER)
	touch $@

#
# mc
#
MC_VER = 4.8.14

$(ARCHIVE)/mc-$(MC_VER).tar.xz:
	$(WGET) http://ftp.midnight-commander.org/mc-$(MC_VER).tar.xz

$(D)/mc: $(D)/bootstrap $(D)/libncurses $(D)/glib2 $(ARCHIVE)/mc-$(MC_VER).tar.xz
	$(REMOVE)/mc-$(MC_VER)
	$(UNTAR)/mc-$(MC_VER).tar.xz
	set -e; cd $(BUILD_TMP)/mc-$(MC_VER); \
		autoreconf -fi; \
		$(BUILDENV) \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=$(DEFAULT_PREFIX) \
			--mandir=/.remove \
			--without-gpm-mouse \
			--disable-doxygen-doc \
			--disable-doxygen-dot \
			--enable-charset \
			--with-screen=ncurses \
			--sysconfdir=/etc \
			--with-homedir=/var/tuxbox/config/mc \
			--without-x \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/mc-$(MC_VER)
	touch $@

#
# nano
#
NANO_VER = 2.2.6

$(ARCHIVE)/nano-$(NANO_VER).tar.gz:
	$(WGET) http://www.nano-editor.org/dist/v2.2/nano-$(NANO_VER).tar.gz

$(D)/nano: $(D)/bootstrap $(ARCHIVE)/nano-$(NANO_VER).tar.gz
	$(REMOVE)/nano-$(NANO_VER)
	$(UNTAR)/nano-$(NANO_VER).tar.gz
	set -e; cd $(BUILD_TMP)/nano-$(NANO_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-nls \
			--enable-tiny \
			--enable-color \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/nano-$(NANO_VER)
	touch $@

#
# rsync
#
RSYNC_VER = 3.1.1

$(ARCHIVE)/rsync-$(RSYNC_VER).tar.gz:
	$(WGET) http://samba.anu.edu.au/ftp/rsync/src/rsync-$(RSYNC_VER).tar.gz

$(D)/rsync: $(D)/bootstrap $(ARCHIVE)/rsync-$(RSYNC_VER).tar.gz
	$(REMOVE)/rsync-$(RSYNC_VER)
	$(UNTAR)/rsync-$(RSYNC_VER).tar.gz
	set -e; cd $(BUILD_TMP)/rsync-$(RSYNC_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc \
			--disable-debug \
			--disable-locale \
		; \
		$(MAKE) all; \
		$(MAKE) install-all DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/rsync-$(RSYNC_VER)
	touch $@

#
# fuse
#
FUSE_VER = 2.9.3

$(ARCHIVE)/fuse-$(FUSE_VER).tar.gz:
	$(WGET) https://github.com/libfuse/libfuse/releases/download/fuse_2_9_4/fuse-2.9.3.tar.gz

$(D)/fuse: $(D)/bootstrap $(ARCHIVE)/fuse-$(FUSE_VER).tar.gz
	$(REMOVE)/fuse-$(FUSE_VER)
	$(UNTAR)/fuse-$(FUSE_VER).tar.gz
	set -e; cd $(BUILD_TMP)/fuse-$(FUSE_VER); \
		$(CONFIGURE) \
			CFLAGS="$(TARGET_CFLAGS) -I$(KERNEL_DIR)/arch/sh" \
			--target=$(TARGET) \
			--prefix=/usr \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
		-rm $(TARGETPREFIX)/etc/udev/rules.d/99-fuse.rules
		-rmdir $(TARGETPREFIX)/etc/udev/rules.d
		-rmdir $(TARGETPREFIX)/etc/udev
		ln -sf sh4-linux-fusermount $(TARGETPREFIX)/usr/bin/fusermount
		ln -sf sh4-linux-ulockmgr_server $(TARGETPREFIX)/usr/bin/ulockmgr_server
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/fuse.pc
	$(REWRITE_LIBTOOL)/libfuse.la
	$(REMOVE)/fuse-$(FUSE_VER)
	touch $@

#
# sdparm
#
SDPARM_VER = 1.09

$(ARCHIVE)/sdparm-$(SDPARM_VER).tgz:
	$(WGET) http://sg.danny.cz/sg/p/sdparm-$(SDPARM_VER).tgz

$(D)/sdparm: $(D)/bootstrap $(ARCHIVE)/sdparm-$(SDPARM_VER).tgz
	$(REMOVE)/sdparm-$(SDPARM_VER)
	$(UNTAR)/sdparm-$(SDPARM_VER).tgz
	set -e; cd $(BUILD_TMP)/sdparm-$(SDPARM_VER); \
		$(CONFIGURE) \
			--prefix= \
			--exec-prefix=/usr \
			--mandir=/.remove \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/sdparm-$(SDPARM_VER)
	touch $@

#
# hddtemp
#
HDDTEMP_VER = 0.3-beta15

$(ARCHIVE)/hddtemp-$(HDDTEMP_VER).tar.bz2:
	$(WGET) http://savannah.c3sl.ufpr.br/hddtemp/hddtemp-$(HDDTEMP_VER).tar.bz2

$(D)/hddtemp: $(D)/bootstrap $(ARCHIVE)/hddtemp-$(HDDTEMP_VER).tar.bz2
	$(REMOVE)/hddtemp-$(HDPARM_VER)
	$(UNTAR)/hddtemp-$(HDPARM_VER).tar.gz
	set -e; cd $(BUILD_TMP)/hddtemp-$(HDPARM_VER); \
		$(CONFIGURE) \
			--prefix= \
			--with-db_path=/var/hddtemp.db \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
		install -d $(TARGETPREFIX)/var/tuxbox/config
		install -m 644 root/release/hddtemp.db $(TARGETPREFIX)/var
	$(REMOVE)/hddtemp-$(HDPARM_VER)
	touch $@

#
# hdparm
#
HDPARM_VER = 9.48

$(ARCHIVE)/hdparm-$(HDPARM_VER).tar.gz:
	$(WGET) http://downloads.sourceforge.net/project/hdparm/hdparm/hdparm-$(HDPARM_VER).tar.gz

$(D)/hdparm: $(D)/bootstrap $(ARCHIVE)/hdparm-$(HDPARM_VER).tar.gz
	$(REMOVE)/hdparm-$(HDPARM_VER)
	$(UNTAR)/hdparm-$(HDPARM_VER).tar.gz
	set -e; cd $(BUILD_TMP)/hdparm-$(HDPARM_VER); \
		$(BUILDENV) \
		$(MAKE) CROSS=$(TARGET)- all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/hdparm-$(HDPARM_VER) $(PKGPREFIX)
	touch $@

#
# parted
#
PARTED_VER = 3.2

$(ARCHIVE)/parted-$(PARTED_VER).tar.xz:
	$(WGET) http://ftp.gnu.org/gnu/parted/parted-$(PARTED_VER).tar.xz

$(D)/parted: $(D)/bootstrap $(D)/libncurses $(D)/libreadline $(D)/e2fsprogs $(ARCHIVE)/parted-$(PARTED_VER).tar.xz
	$(REMOVE)/parted-$(PARTED_VER)
	$(UNTAR)/parted-$(PARTED_VER).tar.xz
	set -e; cd $(BUILD_TMP)/parted-$(PARTED_VER); \
		$(PATCH)/parted-3.2-device-mapper.patch; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--infodir=/.remove \
			--disable-device-mapper \
			--disable-nls \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/libparted.pc
	$(REWRITE_LIBTOOL)/libparted.la
	$(REWRITE_LIBTOOL)/libparted-fs-resize.la
	$(REMOVE)/parted-$(PARTED_VER)
	touch $@

#
# sysstat
#
SYSSTAT_VER = 11.2.0

$(ARCHIVE)/sysstat-$(SYSSTAT_VER).tar.bz2:
	$(WGET) http://pagesperso-orange.fr/sebastien.godard/sysstat-$(SYSSTAT_VER).tar.bz2

$(D)/sysstat: $(D)/bootstrap $(ARCHIVE)/sysstat-$(SYSSTAT_VER).tar.bz2
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	$(UNTAR)/sysstat-$(SYSSTAT_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/sysstat-$(SYSSTAT_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--disable-documentation \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/sysstat-$(SYSSTAT_VER)
	touch $@

#
# autofs
#
AUTOFS_VER = 4.1.4

$(ARCHIVE)/autofs-$(AUTOFS_VER).tar.gz:
	$(WGET) http://www.kernel.org/pub/linux/daemons/autofs/v4/autofs-$(AUTOFS_VER).tar.gz

$(D)/autofs: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/autofs-$(AUTOFS_VER).tar.gz
	$(REMOVE)/autofs-$(AUTOFS_VER)
	$(UNTAR)/autofs-$(AUTOFS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/autofs-$(AUTOFS_VER); \
		$(PATCH)/autofs-4.1.4.patch; \
		cp aclocal.m4 acinclude.m4; \
		autoconf; \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE) all CC=$(TARGET)-gcc STRIP=$(TARGET)-strip; \
		$(MAKE) install INSTALLROOT=$(TARGETPREFIX) SUBDIRS="lib daemon modules"
	install -m 755 $(SKEL_ROOT)/etc/init.d/autofs $(TARGETPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/auto.hotplug $(TARGETPREFIX)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.master $(TARGETPREFIX)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.misc $(TARGETPREFIX)/etc/
	install -m 644 $(SKEL_ROOT)/etc/auto.network $(TARGETPREFIX)/etc/
	$(REMOVE)/autofs-$(AUTOFS_VER)
	touch $@

#
# imagemagick
#
IMAGEMAGICK_VER = 6.7.7-7

$(ARCHIVE)/ImageMagick-$(IMAGEMAGICK_VER).tar.gz:
	$(WGET) ftp://ftp.fifi.org/pub/ImageMagick/ImageMagick-$(IMAGEMAGICK_VER).tar.gz

$(D)/imagemagick: $(D)/bootstrap $(ARCHIVE)/ImageMagick-$(IMAGEMAGICK_VER).tar.gz
	$(REMOVE)/ImageMagick-$(IMAGEMAGICK_VER)
	$(UNTAR)/ImageMagick-$(IMAGEMAGICK_VER).tar.gz
	set -e; cd $(BUILD_TMP)/ImageMagick-$(IMAGEMAGICK_VER); \
		$(BUILDENV) \
		CFLAGS="-O1" \
		PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix=/usr \
			--without-dps \
			--without-fpx \
			--without-gslib \
			--without-jbig \
			--without-jp2 \
			--without-lcms \
			--without-tiff \
			--without-xml \
			--without-perl \
			--disable-openmp \
			--disable-opencl \
			--without-zlib \
			--enable-shared \
			--enable-static \
			--without-x \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ImageMagick.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/MagickCore.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/MagickWand.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/Wand.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/ImageMagick++.pc
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/Magick++.pc
	$(REWRITE_LIBTOOL)/libMagickCore.la
	$(REWRITE_LIBTOOL)/libMagickWand.la
	$(REWRITE_LIBTOOL)/libMagick++.la
	$(REMOVE)/ImageMagick-$(IMAGEMAGICK_VER)
	touch $@

#
# shairport
#
$(D)/shairport: $(D)/bootstrap $(D)/openssl $(D)/howl $(D)/libalsa
	$(REMOVE)/shairport
	[ -d "$(ARCHIVE)/shairport.git" ] && \
	(cd $(ARCHIVE)/shairport.git; git pull; ); \
	[ -d "$(ARCHIVE)/shairport.git" ] || \
	git clone -b 1.0-dev git://github.com/abrasive/shairport.git $(ARCHIVE)/shairport.git; \
	cp -ra $(ARCHIVE)/shairport.git $(BUILD_TMP)/shairport; \
	set -e; cd $(BUILD_TMP)/shairport; \
		sed -i 's|pkg-config|$$PKG_CONFIG|g' configure; \
		PKG_CONFIG=$(HOSTPREFIX)/bin/$(TARGET)-pkg-config \
		$(BUILDENV) \
		$(MAKE); \
		$(MAKE) install PREFIX=$(TARGETPREFIX)/usr
	$(REMOVE)/shairport
	touch $@

#
# dbus
#
DBUS_VER = 1.8.0

$(ARCHIVE)/dbus-$(DBUS_VER).tar.gz:
	$(WGET) http://dbus.freedesktop.org/releases/dbus/dbus-$(DBUS_VER).tar.gz

$(D)/dbus: $(D)/bootstrap $(D)/libexpat $(ARCHIVE)/dbus-$(DBUS_VER).tar.gz
	$(REMOVE)/dbus-$(DBUS_VER)
	$(UNTAR)/dbus-$(DBUS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/dbus-$(DBUS_VER); \
		$(CONFIGURE) \
		CFLAGS="$(TARGET_CFLAGS) -Wno-cast-align" \
			--without-x \
			--prefix=/usr \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--with-console-auth-dir=/run/console/ \
			--without-systemdsystemunitdir \
			--enable-abstract-sockets \
			--disable-systemd \
			--disable-static \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REWRITE_PKGCONF) $(PKG_CONFIG_PATH)/dbus-1.pc
	$(REWRITE_LIBTOOL)/libdbus-1.la
	$(REMOVE)/dbus-$(DBUS_VER)
	touch $@

#
# avahi
#
AVAHI_VER = 0.6.31

$(ARCHIVE)/avahi-$(AVAHI_VER).tar.gz:
	$(WGET) http://www.avahi.org/download/avahi-$(AVAHI_VER).tar.gz

$(D)/avahi: $(D)/bootstrap $(D)/libexpat $(D)/libdaemon $(D)/dbus $(ARCHIVE)/avahi-$(AVAHI_VER).tar.gz
	$(REMOVE)/avahi-$(AVAHI_VER)
	$(UNTAR)/avahi-$(AVAHI_VER).tar.gz
	set -e; cd $(BUILD_TMP)/avahi-$(AVAHI_VER); \
		sed -i 's/\(CFLAGS=.*\)-Werror \(.*\)/\1\2/' configure; \
		sed -i -e 's/-DG_DISABLE_DEPRECATED=1//' -e '/-DGDK_DISABLE_DEPRECATED/d' avahi-ui/Makefile.in; \
		$(CONFIGURE) \
			--prefix=/usr \
			--sysconfdir=/etc \
			--localstatedir=/var \
			--disable-static \
			--disable-mono \
			--disable-monodoc \
			--disable-python \
			--disable-gdbm \
			--disable-gtk \
			--disable-gtk3 \
			--disable-qt3 \
			--disable-qt4 \
			--disable-nls \
			--enable-core-docs \
			--with-distro=none \
		; \
		$(MAKE) all; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/avahi-$(AVAHI_VER)
	touch $@

#
# wget
#
WGET_VER = 1.17.1

$(ARCHIVE)/wget-$(WGET_VER).tar.xz:
	$(WGET) http://ftp.gnu.org/gnu/wget/wget-$(WGET_VER).tar.xz

$(D)/wget: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/wget-$(WGET_VER).tar.xz
	$(REMOVE)/wget-$(WGET_VER)
	$(UNTAR)/wget-$(WGET_VER).tar.xz
	set -e; cd $(BUILD_TMP)/wget-$(WGET_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--with-openssl \
			--with-ssl=openssl \
			--with-libssl-prefix=$(TARGETPREFIX) \
			--disable-ipv6 \
			--disable-debug \
			--disable-nls \
			--disable-opie \
			--disable-digest \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/wget-$(WGET_VER)
	touch $@

#
# coreutils
#
COREUTILS_VER = 8.23

$(ARCHIVE)/coreutils-$(COREUTILS_VER).tar.xz:
	$(WGET) http://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VER).tar.xz

$(D)/coreutils: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/coreutils-$(COREUTILS_VER).tar.xz
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	$(UNTAR)/coreutils-$(COREUTILS_VER).tar.xz
	set -e; cd $(BUILD_TMP)/coreutils-$(COREUTILS_VER); \
		$(PATCH)/coreutils-8.23.patch; \
		export fu_cv_sys_stat_statfs2_bsize=yes; \
		$(CONFIGURE) \
			--prefix=/usr \
			--enable-largefile \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/coreutils-$(COREUTILS_VER)
	touch $@

#
# smartmontools
#
SMARTMONTOOLS_VER = 6.4

$(ARCHIVE)/smartmontools-$(SMARTMONTOOLS_VER).tar.gz:
	$(WGET) http://sourceforge.net/projects/smartmontools/files/smartmontools/$(SMARTMONTOOLS_VER)/smartmontools-$(SMARTMONTOOLS_VER).tar.gz

$(D)/smartmontools: $(D)/bootstrap $(ARCHIVE)/smartmontools-$(SMARTMONTOOLS_VER).tar.gz
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	$(UNTAR)/smartmontools-$(SMARTMONTOOLS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/smartmontools-$(SMARTMONTOOLS_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
		; \
		$(MAKE); \
		$(MAKE) install prefix=$(TARGETPREFIX)/usr
	$(REMOVE)/smartmontools-$(SMARTMONTOOLS_VER)
	touch $@

#
# nfs_utils
#
NFSUTILS_VER = 1.3.3

$(ARCHIVE)/nfs-utils-$(NFSUTILS_VER).tar.bz2:
	$(WGET) http://downloads.sourceforge.net/project/nfs/nfs-utils/$(NFSUTILS_VER)/nfs-utils-$(NFSUTILS_VER).tar.bz2

$(D)/nfs_utils: $(D)/bootstrap $(D)/e2fsprogs $(ARCHIVE)/nfs-utils-$(NFSUTILS_VER).tar.bz2
	$(REMOVE)/nfs-utils-$(NFSUTILS_VER)
	$(UNTAR)/nfs-utils-$(NFSUTILS_VER).tar.bz2
	set -e; cd $(BUILD_TMP)/nfs-utils-$(NFSUTILS_VER); \
		$(PATCH)/nfs-utils-1.3.3.patch; \
		$(CONFIGURE) \
			CC_FOR_BUILD=$(TARGET)-gcc \
			--prefix=/usr \
			--exec-prefix=/usr \
			--mandir=/.remove \
			--disable-gss \
			--enable-ipv6=no \
			--disable-tirpc \
			--disable-nfsv4 \
			--without-tcp-wrappers \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-common $(TARGETPREFIX)/etc/init.d/
	install -m 755 $(SKEL_ROOT)/etc/init.d/nfs-kernel-server $(TARGETPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/exports $(TARGETPREFIX)/etc/
	cd $(TARGETPREFIX) && rm -f sbin/mount.nfs sbin/mount.nfs4 sbin/umount.nfs sbin/umount.nfs4 \
				 sbin/osd_login
	$(REMOVE)/nfs-utils-$(NFSUTILS_VER)
	touch $@

#
# libevent
#
LIBEVENT_VER = 2.0.21-stable

$(ARCHIVE)/libevent-$(LIBEVENT_VER).tar.gz:
	$(WGET) https://github.com/downloads/libevent/libevent/libevent-$(LIBEVENT_VER).tar.gz

$(D)/libevent: $(D)/bootstrap $(ARCHIVE)/libevent-$(LIBEVENT_VER).tar.gz
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	$(UNTAR)/libevent-$(LIBEVENT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libevent-$(LIBEVENT_VER);\
		$(CONFIGURE) \
			--prefix=$(TARGETPREFIX)/usr \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/libevent-$(LIBEVENT_VER)
	touch $@

#
# libnfsidmap
#
LIBNFSIDMAP_VER = 0.25

$(ARCHIVE)/libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz:
	$(WGET) http://www.citi.umich.edu/projects/nfsv4/linux/libnfsidmap/libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz

$(D)/libnfsidmap: $(D)/bootstrap $(ARCHIVE)/libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	$(UNTAR)/libnfsidmap-$(LIBNFSIDMAP_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libnfsidmap-$(LIBNFSIDMAP_VER);\
		$(CONFIGURE) \
		ac_cv_func_malloc_0_nonnull=yes \
			--prefix=$(TARGETPREFIX)/usr \
		; \
		$(MAKE); \
		$(MAKE) install
	$(REMOVE)/libnfsidmap-$(LIBNFSIDMAP_VER)
	touch $@

#
# vsftpd
#
VSFTPD_VER = 3.0.3

$(ARCHIVE)/vsftpd-$(VSFTPD_VER).tar.gz:
	$(WGET) https://security.appspot.com/downloads/vsftpd-$(VSFTPD_VER).tar.gz

$(D)/vsftpd: $(D)/bootstrap $(ARCHIVE)/vsftpd-$(VSFTPD_VER).tar.gz
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	$(UNTAR)/vsftpd-$(VSFTPD_VER).tar.gz
	set -e; cd $(BUILD_TMP)/vsftpd-$(VSFTPD_VER); \
		$(PATCH)/vsftpd-3.0.3.patch; \
		$(MAKE) clean; \
		$(MAKE) $(MAKE_OPTS) CFLAGS="-pipe -Os -g0"; \
		$(MAKE) install PREFIX=$(TARGETPREFIX)
		cp $(CDK_DIR)/root/etc/vsftpd.conf $(TARGETPREFIX)/etc
	install -m 755 $(SKEL_ROOT)/etc/init.d/vsftpd $(TARGETPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/vsftpd.conf $(TARGETPREFIX)/etc/
	$(REMOVE)/vsftpd-$(VSFTPD_VER)
	touch $@

#
# ethtool
#
ETHTOOL_VER = 6

$(ARCHIVE)/ethtool-$(ETHTOOL_VER).tar.gz:
	$(WGET) http://downloads.openwrt.org/sources/ethtool-$(ETHTOOL_VER).tar.gz

$(D)/ethtool: $(D)/bootstrap $(ARCHIVE)/ethtool-$(ETHTOOL_VER).tar.gz
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	$(UNTAR)/ethtool-$(ETHTOOL_VER).tar.gz
	set -e; cd $(BUILD_TMP)/ethtool-$(ETHTOOL_VER); \
		$(CONFIGURE) \
			--prefix=/usr \
			--mandir=/.remove \
			--libdir=$(TARGETPREFIX)/usr/lib \
		; \
		$(MAKE); \
		make install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/ethtool-$(ETHTOOL_VER)
	touch $@

#
# samba
#
SAMBA_VER = 3.6.25

$(ARCHIVE)/samba-$(SAMBA_VER).tar.gz:
	$(WGET) http://ftp.samba.org/pub/samba/stable/samba-$(SAMBA_VER).tar.gz

$(D)/samba: $(D)/bootstrap $(ARCHIVE)/samba-$(SAMBA_VER).tar.gz
	$(REMOVE)/samba-$(SAMBA_VER)
	$(UNTAR)/samba-$(SAMBA_VER).tar.gz
	set -e; cd $(BUILD_TMP)/samba-$(SAMBA_VER); \
		$(PATCH)/samba-3.6.25.patch; \
		cd source3; \
		./autogen.sh; \
		$(BUILDENV) \
		libreplace_cv_HAVE_GETADDRINFO=no \
		libreplace_cv_READDIR_NEEDED=no \
		./configure \
			--build=$(BUILD) \
			--host=$(TARGET) \
			--prefix= \
			--includedir=/usr/include \
			--exec-prefix=/usr \
			--disable-pie \
			--disable-avahi \
			--disable-cups \
			--disable-relro \
			--disable-swat \
			--disable-shared-libs \
			--disable-socket-wrapper \
			--disable-nss-wrapper \
			--disable-smbtorture4 \
			--disable-fam \
			--disable-iprint \
			--disable-dnssd \
			--disable-pthreadpool \
			--disable-dmalloc \
			--with-included-iniparser \
			--with-included-popt \
			--with-sendfile-support \
			--without-aio-support \
			--without-cluster-support \
			--without-ads \
			--without-krb5 \
			--without-dnsupdate \
			--without-automount \
			--without-ldap \
			--without-pam \
			--without-pam_smbpass \
			--without-winbind \
			--without-wbclient \
			--without-syslog \
			--without-nisplus-home \
			--without-quotas \
			--without-sys-quotas \
			--without-utmp \
			--without-acl-support \
			--with-configdir=/etc/samba \
			--with-privatedir=/etc/samba \
			--with-mandir=no \
			--with-piddir=/var/run \
			--with-logfilebase=/var/log \
			--with-lockdir=/var/lock \
			--with-swatdir=/usr/share/swat \
			--disable-cups \
		; \
		$(MAKE) $(MAKE_OPTS); \
		$(MAKE) $(MAKE_OPTS) installservers installbin installscripts installdat installmodules \
			SBIN_PROGS="bin/smbd bin/nmbd bin/winbindd" DESTDIR=$(TARGETPREFIX) prefix=./. ; \
	install -m 755 $(SKEL_ROOT)/etc/init.d/samba $(TARGETPREFIX)/etc/init.d/
	install -m 644 $(SKEL_ROOT)/etc/smb.conf $(TARGETPREFIX)/etc/samba/
	$(REMOVE)/samba-$(SAMBA_VER)
	touch $@

#
# ntp
#
NTP_VER = 4.2.8p3

$(ARCHIVE)/ntp-$(NTP_VER).tar.gz:
	$(WGET) http://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-4.2/ntp-$(NTP_VER).tar.gz

$(D)/ntp: $(D)/bootstrap $(ARCHIVE)/ntp-$(NTP_VER).tar.gz
	$(REMOVE)/ntp-$(NTP_VER)
	$(UNTAR)/ntp-$(NTP_VER).tar.gz
	set -e; cd $(BUILD_TMP)/ntp-$(NTP_VER); \
		$(PATCH)/ntp-4.2.8p3.patch; \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--disable-tick \
			--disable-tickadj \
			--with-yielding-select=yes \
			--without-ntpsnmpd \
			--disable-debugging \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/ntp-$(NTP_VER)
	touch $@

#
# wireless_tools
#
WIRELESSTOOLS_VER = 29

$(ARCHIVE)/wireless_tools.$(WIRELESSTOOLS_VER).tar.gz:
	$(WGET) http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/wireless_tools.$(WIRELESSTOOLS_VER).tar.gz

$(D)/wireless_tools: $(D)/bootstrap $(ARCHIVE)/wireless_tools.$(WIRELESSTOOLS_VER).tar.gz
	$(REMOVE)/wireless_tools.$(WIRELESSTOOLS_VER)
	$(UNTAR)/wireless_tools.$(WIRELESSTOOLS_VER).tar.gz
	set -e; cd $(BUILD_TMP)/wireless_tools.$(WIRELESSTOOLS_VER); \
		$(PATCH)/wireless-tools.29.patch; \
		$(MAKE) CC="$(TARGET)-gcc" CFLAGS="$(TARGET_CFLAGS) -I."; \
		$(MAKE) install PREFIX=$(TARGETPREFIX)/usr INSTALL_MAN=$(TARGETPREFIX)/.remove
	$(REMOVE)/wireless_tools.$(WIRELESSTOOLS_VER)
	touch $@

#
# libnl
#
LIBNL_VER = 2.0

$(ARCHIVE)/libnl-$(LIBNL_VER).tar.gz:
	$(WGET) http://www.carisma.slowglass.com/~tgr/libnl/files/libnl-$(LIBNL_VER).tar.gz

$(D)/libnl: $(D)/bootstrap $(D)/openssl $(ARCHIVE)/libnl-$(LIBNL_VER).tar.gz
	$(REMOVE)/libnl-$(LIBNL_VER)
	$(UNTAR)/libnl-$(LIBNL_VER).tar.gz
	set -e; cd $(BUILD_TMP)/libnl-$(LIBNL_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--bindir=/.remove \
			--mandir=/.remove \
			--infodir=/.remove \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/libnl-$(LIBNL_VER)
	touch $@

#
# wpa_supplicant
#
WPA_SUPPLICANT_VER = 0.7.3

$(ARCHIVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz:
	$(WGET) http://hostap.epitest.fi/releases/wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz

$(D)/wpa_supplicant: $(D)/bootstrap $(D)/openssl $(D)/wireless_tools $(ARCHIVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	$(UNTAR)/wpa_supplicant-$(WPA_SUPPLICANT_VER).tar.gz
	set -e; cd $(BUILD_TMP)/wpa_supplicant-$(WPA_SUPPLICANT_VER)/wpa_supplicant; \
		cp -f defconfig .config; \
		sed -i 's/CONFIG_DRIVER_NL80211=y/#CONFIG_DRIVER_NL80211=y/' .config; \
		sed -i 's/#CONFIG_IEEE80211W=y/CONFIG_IEEE80211W=y/' .config; \
		sed -i 's/#CONFIG_OS=unix/CONFIG_OS=unix/' .config; \
		sed -i 's/#CONFIG_TLS=openssl/CONFIG_TLS=openssl/' .config; \
		sed -i 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/' .config; \
		sed -i 's/#CONFIG_INTERWORKING=y/CONFIG_INTERWORKING=y/' .config; \
		export CFLAGS="-pipe -Os -Wall -g0 -I$(TARGETPREFIX)/usr/include"; \
		export CPPFLAGS="-I$(TARGETPREFIX)/usr/include"; \
		export LIBS="-L$(TARGETPREFIX)/usr/lib -Wl,-rpath-link,$(TARGETPREFIX)/usr/lib"; \
		export LDFLAGS="-L$(TARGETPREFIX)/usr/lib"; \
		export DESTDIR=$(TARGETPREFIX); \
		$(MAKE) CC=$(TARGET)-gcc; \
		$(MAKE) install BINDIR=/usr/sbin DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/wpa_supplicant-$(WPA_SUPPLICANT_VER)
	touch $@

#
# xupnpd
#
$(D)/xupnpd: $(D)/bootstrap
	$(REMOVE)/xupnpd
	[ -d "$(ARCHIVE)/xupnpd.git" ] && \
	(cd $(ARCHIVE)/xupnpd.git; git pull; ); \
	[ -d "$(ARCHIVE)/xupnpd.git" ] || \
	git clone git://github.com/clark15b/xupnpd.git $(ARCHIVE)/xupnpd.git; \
	cp -ra $(ARCHIVE)/xupnpd.git $(BUILD_TMP)/xupnpd; \
	cd $(BUILD_TMP)/xupnpd && $(PATCH)/xupnpd.patch
	set -e; cd $(BUILD_TMP)/xupnpd/src; \
		$(BUILDENV) \
		$(MAKE) TARGET=$(TARGET) sh4; \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	$(REMOVE)/xupnpd
	touch $@

#
# udpxy
#
UDPXY_VER = 1.0.23-9

$(ARCHIVE)/udpxy.$(UDPXY_VER)-prod.tar.gz:
	$(WGET) http://www.udpxy.com/download/1_23/udpxy.$(UDPXY_VER)-prod.tar.gz

$(D)/udpxy: $(D)/bootstrap $(ARCHIVE)/udpxy.$(UDPXY_VER)-prod.tar.gz
	$(REMOVE)/udpxy-$(UDPXY_VER)
	$(UNTAR)/udpxy.$(UDPXY_VER)-prod.tar.gz
	set -e; cd $(BUILD_TMP)/udpxy-$(UDPXY_VER); \
		$(PATCH)/udpxy-1.0.23-0.patch; \
		$(BUILDENV) \
		$(MAKE) CC=$(TARGET)-gcc CCKIND=gcc; \
		$(MAKE) install INSTALLROOT=$(TARGETPREFIX)/usr MANPAGE_DIR=$(TARGETPREFIX)/.remove
	$(REMOVE)/udpxy-$(UDPXY_VER)
	touch $@

#
# openvpn
#
OPENVPN_VER = 2.3.10

$(ARCHIVE)/openvpn-$(OPENVPN_VER).tar.xz:
	$(WGET) http://swupdate.openvpn.org/community/releases/openvpn-$(OPENVPN_VER).tar.xz

$(D)/openvpn: $(D)/bootstrap $(D)/openssl $(D)/lzo $(ARCHIVE)/openvpn-$(OPENVPN_VER).tar.xz
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	$(UNTAR)/openvpn-$(OPENVPN_VER).tar.xz
	set -e; cd $(BUILD_TMP)/openvpn-$(OPENVPN_VER); \
		$(CONFIGURE) \
			--target=$(TARGET) \
			--prefix=/usr \
			--mandir=/.remove \
			--docdir=/.remove \
			--disable-selinux \
			--disable-systemd \
			--disable-plugins \
			--disable-debug \
			--disable-pkcs11 \
			--enable-password-save \
			--enable-small \
		; \
		$(MAKE); \
		$(MAKE) install DESTDIR=$(TARGETPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/openvpn $(TARGETPREFIX)/etc/init.d/
	$(REMOVE)/openvpn-$(OPENVPN_VER)
	touch $@

#
# openssh
#
OPENSSH_VER = 7.1p1

$(ARCHIVE)/openssh-$(OPENSSH_VER).tar.gz:
	$(WGET) http://artfiles.org/openbsd/OpenSSH/portable/openssh-$(OPENSSH_VER).tar.gz

$(D)/openssh: $(D)/bootstrap $(D)/zlib $(D)/openssl $(ARCHIVE)/openssh-$(OPENSSH_VER).tar.gz
	$(REMOVE)/openssh-$(OPENSSH_VER)
	$(UNTAR)/openssh-$(OPENSSH_VER).tar.gz
	set -e; cd $(BUILD_TMP)/openssh-$(OPENSSH_VER); \
		CC=$(TARGET)-gcc; \
		./configure \
			$(CONFIGURE_OPTS) \
			--prefix=/usr \
			--mandir=/.remove \
			--sysconfdir=/etc/ssh \
			--libexecdir=/sbin \
			--with-privsep-path=/share/empty \
			--with-cppflags="-pipe -Os -I$(TARGETPREFIX)/usr/include" \
			--with-ldflags=-"L$(TARGETPREFIX)/usr/lib" \
		; \
		$(MAKE); \
		$(MAKE) install-nokeys prefix=$(TARGETPREFIX)
	install -m 755 $(SKEL_ROOT)/etc/init.d/openssh $(TARGETPREFIX)/etc/init.d/
	$(REMOVE)/openssh-$(OPENSSH_VER)
	touch $@
