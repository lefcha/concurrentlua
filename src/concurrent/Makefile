DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/$(LUAVERSION)
MODDIR = $(SHAREDIR)/concurrent

LUAVERSION = 5.1

SHARE = init.lua \
	option.lua \
	process.lua \
	message.lua \
	scheduler.lua \
	register.lua \
	monitor.lua \
	link.lua \
	root.lua

all: $(SHARE)

$(SHARE):

install: $(SHARE)
	mkdir -p $(DESTDIR)$(MODDIR) && \
	cp -f $(SHARE) $(DESTDIR)$(MODDIR) && \
	chmod 0644 $(DESTDIR)$(MODDIR)/$(SHARE)
	cd distributed && $(MAKE) install

uninstall:
	cd $(DESTDIR)$(MODDIR) && \
	rm -f $(SHARE)
	cd distributed && $(MAKE) uninstall

clean:
	rm -f *~
	cd distributed && $(MAKE) clean
