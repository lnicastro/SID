SRC = src

default: all

all clean :
	mkdir -p lib
	@ cd $(SRC) ; ${MAKE} $@

linux :
	@ cd $(SRC) ; cp Makefile.linux Makefile

darwin :
	@ cd $(SRC) ; cp Makefile.darwin Makefile

