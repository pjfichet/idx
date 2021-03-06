# Packaging directory
DESTDIR=
# Prefix directory
PREFIX=$(HOME)/.local
# Where to place binaries
BINDIR=$(PREFIX)/bin
# Where to place manuals
MANDIR=$(PREFIX)/share/man

all: idx idx.1

%.1 %.7: %.man
	sed -e "s|@BINDIR@|$(BINDIR)|g" $< > $@

idx: idx.sh
	cp $< $@

$(MANDIR)/man1/%: %
	test -d $(DESTDIR)$(MANDIR)/man1 || mkdir -p $(DESTDIR)$(MANDIR)/man1
	install  -c -m 644 $< $@

$(BINDIR)/%: %
	test -d $(DESTDIR)$(BINDIR) || mkdir -p $(DESTDIR)$(BINDIR)
	install  -c -m 755 $< $@


install: $(DESTDIR)$(MANDIR)/man1/idx.1 $(DESTDIR)$(BINDIR)/idx

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/idx
	rm -f $(DESTDIR)$(MANDIR)/man1/idx.1

clean:
	rm -f idx.1 idx

