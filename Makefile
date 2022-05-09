# configurable options:

# Avoid installing native symlinks if not yes
USE_NATIVE_LINKS ?= yes
# Avoid installing clang symlinks if not yes
USE_CLANG_WRAPPERS ?= yes
# Avoid installing binutils symlinks if not yes
USE_BINUTILS_WRAPPERS ?= yes

# Prepend toolchain prefix to 'clang' in c89/c99 wrapeprs.
#    Should usually be '${CHOST}-'.
TOOLCHAIN_PREFIX ?=

EPREFIX ?=

PN = llvm-conf
PV = git
P = $(PN)-$(PV)

PREFIX = $(EPREFIX)/usr
BINDIR = $(PREFIX)/bin
DOCDIR = $(PREFIX)/share/doc/$(P)
SHAREDIR = $(PREFIX)/share/$(PN)

SUBLIBDIR = lib
LIBDIR = $(PREFIX)/$(SUBLIBDIR)

MKDIR_P = mkdir -p -m 755
INSTALL_EXE = install -m 755
INSTALL_DATA = install -m 644

all: .llvm-conf .c89 .c99

clean:
	rm -f .llvm-conf .c89 .c99

.llvm-conf: llvm-conf
	sed \
		-e '1s:/:$(EPREFIX)/:' \
		-e 's:@GENTOO_EPREFIX@:$(EPREFIX):g' \
		-e 's:@GENTOO_LIBDIR@:$(SUBLIBDIR):g' \
		-e 's:@PV@:$(PV):g' \
		-e 's:@USE_NATIVE_LINKS@:$(USE_NATIVE_LINKS):g' \
		-e 's:@USE_CLANG_WRAPPERS@:$(USE_CLANG_WRAPPERS):g' \
		-e 's:@USE_BINUTILS_WRAPPERS@:$(USE_BINUTILS_WRAPPERS):g' \
		$< > $@
	chmod a+rx $@

.c89: c89
	sed \
		-e '1s:/:$(EPREFIX)/:' \
		-e 's:@PV@:$(PV):g' \
		-e 's:@TOOLCHAIN_PREFIX@:$(TOOLCHAIN_PREFIX):g' \
		$< > $@
	chmod a+rx $@

.c99: c99
	sed \
		-e '1s:/:$(EPREFIX)/:' \
		-e 's:@PV@:$(PV):g' \
		-e 's:@TOOLCHAIN_PREFIX@:$(TOOLCHAIN_PREFIX):g' \
		$< > $@
	chmod a+rx $@

install: all
	$(MKDIR_P) $(DESTDIR)$(BINDIR) $(DESTDIR)$(SHAREDIR) $(DESTDIR)$(DOCDIR)
	$(INSTALL_EXE) .llvm-conf $(DESTDIR)$(BINDIR)/llvm-conf
	$(INSTALL_EXE) .c89 $(DESTDIR)$(SHAREDIR)/c89
	$(INSTALL_EXE) .c99 $(DESTDIR)$(SHAREDIR)/c99
	if [ "$(USE_NATIVE_LINKS)" = yes ] ; then \
		$(INSTALL_EXE) .c89 $(DESTDIR)$(BINDIR)/c89 && \
		$(INSTALL_EXE) .c99 $(DESTDIR)$(BINDIR)/c99 ;  \
	fi
	$(INSTALL_DATA) README $(DESTDIR)$(DOCDIR)

uninstall:
	rm -rf ${DESTDIR}${BINDIR}/llvm-conf
	rm -rf ${DESTDIR}${BINDIR}/c89
	rm -rf ${DESTDIR}${BINDIR}/c99
	rm -rf ${DESTDIR}${SHAREDIR}
	rm -rf ${DESTDIR}${DOCDIR}

dist:
	@if [ "$(PV)" = "git" ] ; then \
		printf "please run: make dist PV=xxx\n(where xxx is a git tag)\n" ; \
		exit 1 ; \
	fi
	git archive --prefix=$(P)/ v$(PV) | xz > $(P).tar.xz

distcheck: dist
	@set -ex; \
	rm -rf $(P); \
	tar xf $(P).tar.xz; \
	pushd $(P) >/dev/null; \
	$(MAKE) install DESTDIR=`pwd`/foo; \
	rm -rf foo; \
	popd >/dev/null; \
	rm -rf $(P)

.PHONY: all clean dist install
