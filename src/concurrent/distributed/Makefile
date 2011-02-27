DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/5.1
SHAREMODDIR = $(SHAREDIR)/concurrent/distributed

SHARE = init.lua \
	network.lua \
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
	if test ! -d $(DESTDIR)$(SHAREMODDIR); \
		then mkdir -p $(DESTDIR)$(SHAREMODDIR); \
	fi
	cp -f $(SHARE) $(DESTDIR)$(SHAREMODDIR) && \
		cd $(DESTDIR)$(SHAREMODDIR) && \
		chmod 0644 $(SHARE)

uninstall:
	cd $(DESTDIR)$(SHAREMODDIR) && \
	    	rm -f $(SHARE)

clean:
	rm -f *~
