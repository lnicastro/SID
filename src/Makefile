# Last change: 09/11/2017
#
MAKE ?= make
CC   ?= gcc
CCXX ?= g++
LD   = g++

CPPFLAGS = -I./ -I../contrib/HtmIndex/include -I../contrib/HealPix3 -Wall -O3 -fPIC #-DDEBUG_PRINT

LDFLAGS = -shared

LIBS = ../contrib/HtmIndex/lib/libSpatialIndex.a ../contrib/HealPix3/lib/libHealP3.a

LIBUDF = udf_dif.so

# The C++ library modules
CCMODS = htmCircleRegion htmRectRegion getHTMid getHTMidByName getHTMnameById \
	getHTMNeighb getHTMNeighbC getHTMsNeighb getHTMBary getHTMBaryC getHTMBaryDist \
	getHealPid getHealPBaryDist getHealPMaxS getHealPBary getHealPNeighbC getHealPNeighb getHealPBaryC \
	getHealPBound getHealPBoundC myHealPCone myHealPRect myHealPRect4v difflist_ui skysep_h  udf

LIBOBJS = ${CCMODS:%=%.o}

HFILES =

lib: $(LIBOBJS)
	$(LD) $(LDFLAGS) $(LIBOBJS) $(LIBS) -o $(LIBUDF)

udf.o:
	$(CCXX) `mysql_config --include` -Wall -O3 -fPIC -c udf.cc

install: $(LIBOBJS)
	@pd="`mysql_config --plugindir`"; \
	echo "Copying $(LIBUDF) to MySQL plugin dir $$pd"; \
	cp -a $(LIBUDF) $$pd

clean:
	rm -rf *.o $(LIBUDF)
