MAKE ?= make

HPXDIR = contrib/HealPix3
HTMDIR = contrib/HtmIndex
SPHEDIR = contrib/Spherematch

SRCDIR = src

FILES = Makefile contrib src sql

default: healp htm sphem lib

# Compile HEALPix library
healp: $(HPXDIR)
	@cd $(HPXDIR) ; $(MAKE)

# Compile HTM library
htm: $(HTMDIR)
	@cd $(HTMDIR) ; $(MAKE)

# Compile Spherematch library
sphem: $(SPHEDIR)
	@cd $(SPHEDIR) ; $(MAKE)

# Compile source library
lib: $(SRCDIR)
	@cd $(SRCDIR) ; $(MAKE)

install:
	@cd $(SRCDIR) ; $(MAKE) $@
	@cd sql ; $(MAKE) $@

clean:
	@cd $(HPXDIR) ; $(MAKE) $@
	@cd $(HTMDIR) ; $(MAKE) $@
	@cd $(SPHEDIR) ; $(MAKE) $@
	@cd $(SRCDIR) ; $(MAKE) $@
