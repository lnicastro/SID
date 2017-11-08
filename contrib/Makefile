MAKE ?= make
CC   ?= gcc
CCXX ?= g++

HPXDIR = HealPix3
HTMDIR = HtmIndex
SPHEDIR = Spherematch

default: healp htm sphem

# Compile HEALPix library
healp: $(HPXDIR)
	@cd $(HPXDIR) ; $(MAKE)

# Compile HTM library
htm: $(HTMDIR)
	@cd $(HTMDIR) ; $(MAKE)

# Compile Spherematch library
sphem: $(SPHEDIR)
	@cd $(SPHEDIR) ; $(MAKE)

clean:
	@cd $(HPXDIR) ; $(MAKE) clean
	@cd $(HTMDIR) ; $(MAKE) clean
	@cd $(SPHEDIR) ; $(MAKE) clean
