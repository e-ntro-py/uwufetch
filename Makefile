NAME = uwufetch
BIN_FILES = uwufetch.c
LIB_FILES = fetch.c
UWUFETCH_VERSION = $(shell git describe --tags)
CFLAGS = -O3 -DUWUFETCH_VERSION=\"$(UWUFETCH_VERSION)\"
CFLAGS_DEBUG = -Wall -Wextra -g -pthread -DUWUFETCH_VERSION=\"$(UWUFETCH_VERSION)\"
CC = cc
AR = ar
DESTDIR = /usr
RELEASE_SCRIPTS = release_scripts/*.sh
PLATFORM = $(shell uname)
PLATFORM_ABBR = $(PLATFORM)

ifeq ($(PLATFORM), Linux)
	PREFIX		= bin
	LIBDIR		= lib
	ETC_DIR		= /etc
	MANDIR		= share/man/man1
	PLATFORM_ABBR = linux
	ifeq ($(shell uname -o), Android)
		DESTDIR	= /data/data/com.termux/files/usr
		ETC_DIR = $(DESTDIR)/etc
		PLATFORM_ABBR = android
	endif
else ifeq ($(PLATFORM), Darwin)
	PREFIX		= local/bin
	LIBDIR		= local/lib
	ETC_DIR		= /etc
	MANDIR		= local/share/man/man1
	PLATFORM_ABBR = macos
else ifeq ($(PLATFORM), FreeBSD)
	CFLAGS		+= -D__FREEBSD__ -D__BSD__
	CFLAGS_DEBUG += -D__FREEBSD__ -D__BSD__
	PREFIX		= bin
	LIBDIR		= lib
	ETC_DIR		= /etc
	MANDIR		= share/man/man1
	PLATFORM_ABBR = freebsd
else ifeq ($(PLATFORM), OpenBSD)
	CFLAGS		+= -D__OPENBSD__ -D__BSD__
	CFLAGS_DEBUG += -D__OPENBSD__ -D__BSD__
	PREFIX		= bin
	LIBDIR		= lib
	ETC_DIR		= /etc
	MANDIR		= share/man/man1
	PLATFORM_ABBR = openbsd
else ifeq ($(PLATFORM), windows32)
	CC				= gcc
	PREFIX			= "C:\Program Files"
	LIBDIR			=
	MANDIR			=
	RELEASE_SCRIPTS = release_scripts/*.ps1
	PLATFORM_ABBR	= win64
	EXT				= .exe
else ifeq ($(PLATFORM), linux4win)
	CC				= x86_64-w64-mingw32-gcc
	PREFIX			=
	CFLAGS			+= -D_WIN32
	LIBDIR			=
	MANDIR			=
	RELEASE_SCRIPTS = release_scripts/*.ps1
	PLATFORM_ABBR	= win64
	EXT				= .exe
endif

build: $(BIN_FILES) lib
	$(CC) $(CFLAGS) -o $(NAME) $(BIN_FILES) lib$(LIB_FILES:.c=.a)

lib: $(LIB_FILES)
	$(CC) $(CFLAGS) -fPIC -c -o $(LIB_FILES:.c=.o) $(LIB_FILES)
	$(AR) rcs lib$(LIB_FILES:.c=.a) $(LIB_FILES:.c=.o)
	$(CC) $(CFLAGS) -shared -o lib$(LIB_FILES:.c=.so) $(LIB_FILES:.c=.o)

release: build
	mkdir -pv $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp $(RELEASE_SCRIPTS) $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp -r res $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp $(NAME)$(EXT) $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp $(NAME).1.gz $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp lib$(LIB_FILES:.c=.so) $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp $(LIB_FILES:.c=.h) $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
	cp default.config $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
ifeq ($(PLATFORM), linux4win)
	zip -9r $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR).zip $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
else
	tar -czf $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR).tar.gz $(NAME)_$(UWUFETCH_VERSION)-$(PLATFORM_ABBR)
endif

debug: CFLAGS = $(CFLAGS_DEBUG)
debug: build
	./$(NAME) $(ARGS)

install: build
	mkdir -pv $(DESTDIR)/$(PREFIX) $(DESTDIR)/$(LIBDIR)/$(NAME) $(DESTDIR)/$(MANDIR) $(DESTDIR)/$(ETC_DIR)/$(NAME)
	cp $(NAME) $(DESTDIR)/$(PREFIX)
	cp lib$(LIB_FILES:.c=.so) $(DESTDIR)/$(LIBDIR)
	cp $(LIB_FILES:.c=.h) $(DESTDIR)/include
	cp -r res/* $(DESTDIR)/$(LIBDIR)/$(NAME)
	cp default.config $(DESTDIR)/$(ETC_DIR)/$(NAME)/config
	cp ./$(NAME).1.gz $(DESTDIR)/$(MANDIR)

uninstall:
	rm -f $(DESTDIR)/$(PREFIX)/$(NAME)
	rm -rf $(DESTDIR)/$(LIBDIR)/uwufetch
	rm -f $(DESTDIR)/$(LIBDIR)/lib$(LIB_FILES:.c=.so)
	rm -f $(DESTDIR)/include/$(LIB_FILES:.c=.h)
	rm -rf $(ETC_DIR)/uwufetch
	rm -f $(DESTDIR)/$(MANDIR)/$(NAME).1.gz

clean:
	rm -rf $(NAME) $(NAME)_* *.o *.so *.a *.exe

man:
	gzip --keep $(NAME).1

man_debug:
	@clear
	man -P cat ./uwufetch.1
