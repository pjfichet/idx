
# Packaging directory
DESTDIR=
# Prefix directory
PREFIX=/opt/utroff
# Where to place binaries
BINDIR=$(PREFIX)/bin
# Where to place libraries
MANDIR=$(PREFIX)/man
# Install binary
INSTALL = /usr/bin/install

.SUFFIXES: .sh .1 .7 .man


FILES=idx.1 idx

all: $(FILES)

.man.1 .man.7:
	sed -e "s|@BINDIR@|$(BINDIR)|g" $< > $@

.sh:
	cp $< $@

$(DESTDIR)$(BINDIR) \
$(DESTDIR)$(MANDIR)/man1:
	test -d $@ || mkdir -p $@

$(DESTDIR)$(MANDIR)/man1/%: % $(DESTDIR)$(MANDIR)/man1
	$(INSTALL) -c -m 644 $(@F) $@

$(DESTDIR)$(BINDIR)/%: % $(DESTDIR)$(BINDIR)
	$(INSTALL) -c $(@F) $@

install: $(DESTDIR)$(BINDIR)/idx $(DESTDIR)$(MANDIR)/man1/idx.1

uninstall:
	rm $(DESTDIR)$(BINDIR)/idx
	rmdir $(DESTDIR)$(BINDIR)
	rm $(DESTDIR)$(MANDIR)/man1/idx.1
	rmdir $(DESTDIR)$(MANDIR)/man1
	rmdir $(DESTDIR)$(MANDIR)

clean:
	rm -f $(FILES)

