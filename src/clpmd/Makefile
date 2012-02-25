DESTDIR = 
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin

BIN = clpmd

all: $(BIN)

$(BIN):

install: all
	mkdir -p $(DESTDIR)$(BINDIR) && \
	cp -f $(BIN) $(DESTDIR)$(BINDIR) && \
	chmod 0755 $(DESTDIR)$(BINDIR)/$(BIN)

uninstall:
	cd $(DESTDIR)$(BINDIR) && \
	    	rm -f $(BIN)

clean:
	rm -f *~
