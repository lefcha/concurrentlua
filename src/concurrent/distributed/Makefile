DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/$(LUAVERSION)
MODDIR = $(SHAREDIR)/concurrent/distributed

LUAVERSION = 5.1

SHARE = network.lua \
	node.lua \
	cookie.lua \
	process.lua \
	message.lua \
	scheduler.lua \
	register.lua \
	link.lua \
	monitor.lua

all: $(SHARE)

$(SHARE):

install:
	mkdir -p $(DESTDIR)$(MODDIR) && \
	cp -f $(SHARE) $(DESTDIR)$(MODDIR) && \
	chmod 0644 $(DESTDIR)$(MODDIR)/$(SHARE)

uninstall:
	cd $(DESTDIR)$(MODDIR) && \
	rm -f $(SHARE)

clean:
	rm -f *~
