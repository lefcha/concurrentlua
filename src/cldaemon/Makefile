DESTDIR = 
PREFIX = /usr/local
LIBDIR = $(PREFIX)/lib/lua/5.1

INCDIRS = -I/usr/local/include
LIBDIRS = -L/usr/local/lib

MYCFLAGS = -Wall -g -fpic
MYLDFLAGS = -shared

CFLAGS = $(MYCFLAGS) $(INCDIRS)
LDFLAGS = $(MYLDFLAGS) $(LIBDIRS)

LIBS = -llua

LIB = cldaemon.so
OBJ = cldaemon.o

all: $(LIB)

$(LIB): $(OBJ)
	$(CC) -o $(LIB) $(LDFLAGS) $(OBJ) $(LIBS)

$(OBJ):

install: all
	if test ! -d $(DESTDIR)$(LIBDIR); \
		then mkdir -p $(DESTDIR)$(LIBDIR); \
	fi
	cp -f $(LIB) $(DESTDIR)$(LIBDIR)/$(LIB) && \
	chmod 0755 $(DESTDIR)$(LIBDIR)/$(LIB)

uninstall:
	cd $(DESTDIR)$(LIBDIR) && \
	rm -f $(LIB)

clean:
	rm -f $(OBJ) $(LIB) *~
