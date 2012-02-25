DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/$(LUAVERSION)
SHAREMODDIR = $(SHAREDIR)/concurrent/distributed

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
	mkdir -p $(DESTDIR)$(SHAREMODDIR) && \
	cp -f $(SHARE) $(DESTDIR)$(SHAREMODDIR) && \
	chmod 0644 $(DESTDIR)$(SHAREMODDIR)/$(SHARE)

uninstall:
	cd $(DESTDIR)$(SHAREMODDIR) && \
	rm -f $(SHARE)

clean:
	rm -f *~
