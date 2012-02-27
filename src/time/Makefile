DESTDIR = 
PREFIX = /usr/local
LIBDIR = $(PREFIX)/lib/lua/$(LUAVERSION)/concurrent

LUAVERSION = 5.1

MYCFLAGS =
MYLDFLAGS =
MYLIBS =

INCDIRS =
LIBDIRS =

LIBLUA = -llua

CFLAGS = -Wall -O -fpic $(INCDIRS) $(MYCFLAGS)
LDFLAGS = -shared -fpic $(LIBDIRS) $(MYLDFLAGS)
LIBS = $(LIBLUA) $(MYLIBS)

LIB = time.so
OBJ = time.o

all: $(LIB)

$(LIB): $(OBJ)
	$(CC) -o $(LIB) $(LDFLAGS) $(OBJ) $(LIBS)

$(OBJ):

install: all
	mkdir -p $(DESTDIR)$(LIBDIR) && \
	cp -f $(LIB) $(DESTDIR)$(LIBDIR)/$(LIB) && \
	chmod 0755 $(DESTDIR)$(LIBDIR)/$(LIB)

uninstall:
	cd $(DESTDIR)$(LIBDIR) && \
	rm -f $(LIB) 

clean:
	rm -f $(OBJ) $(LIB) *~
