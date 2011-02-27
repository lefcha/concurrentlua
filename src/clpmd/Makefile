DESTDIR = 
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin

BIN = clpmd

all: $(BIN)

$(BIN):

install: all
	if test ! -d $(DESTDIR)$(BINDIR); \
		then mkdir -p $(DESTDIR)$(BINDIR); \
	fi
	cp -f $(BIN) $(DESTDIR)$(BINDIR) && \
		cd $(DESTDIR)$(BINDIR) && \
		chmod 0755 $(BIN)

uninstall:
	cd $(DESTDIR)$(BINDIR) && \
	    	rm -f $(BIN)

clean:
	rm -f *~
