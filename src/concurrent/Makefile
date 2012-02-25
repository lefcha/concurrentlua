DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/$(LUAVERSION)
SHAREMODDIR = $(SHAREDIR)/concurrent

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

install:
	mkdir -p $(DESTDIR)$(SHAREMODDIR) && \
	cp -f $(SHARE) $(DESTDIR)$(SHAREMODDIR) && \
	chmod 0644 $(DESTDIR)$(SHAREMODDIR)/$(SHARE)
	cd distributed && $(MAKE) install

uninstall:
	cd $(DESTDIR)$(SHAREMODDIR) && \
	rm -f $(SHARE)
	cd distributed && $(MAKE) uninstall

clean:
	rm -f *~
	cd distributed && $(MAKE) clean
