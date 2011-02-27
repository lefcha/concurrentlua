DESTDIR = 
PREFIX = /usr/local
SHAREDIR = $(PREFIX)/share/lua/5.1
SHAREMODDIR = $(SHAREDIR)/concurrent

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
	if test ! -d $(DESTDIR)$(SHAREMODDIR); \
		then mkdir -p $(DESTDIR)$(SHAREMODDIR); \
	fi
	cp -f $(SHARE) $(DESTDIR)$(SHAREMODDIR) && \
		cd $(DESTDIR)$(SHAREMODDIR) && \
		chmod 0644 $(SHARE)
	cd distributed && $(MAKE) install

uninstall:
	cd $(DESTDIR)$(SHAREMODDIR) && \
	    	rm -f $(SHARE)
	cd distributed && $(MAKE) uninstall

clean:
	rm -f *~
	cd distributed && $(MAKE) clean
