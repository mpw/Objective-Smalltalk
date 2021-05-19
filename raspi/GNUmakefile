# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = raspi

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libraspi


OBJCFLAGS += -g -Os -Wno-import 


libraspi_HEADER_FILES = \
	MPWBCMStore.h	\

libraspi_HEADER_FILES_INSTALL_DIR = /stsh


libraspi_OBJC_FILES = \
	MPWBCMStore.m	\
	MPWGPIOPin.m	\


libraspi_C_FILES = \




LIBRARIES_DEPEND_UPON += -lObjectiveSmalltalk  -lMPWFoundation -lgnustep-base -lbcm2835

LDFLAGS += -L ${HOME}/Build/obj 


libraspi_INCLUDE_DIRS += -I.headers -I. -I../../MPWFoundation/.headers/ -I../.headers/

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

before-all ::
	
#	@$(MKDIRS) $(libMPWFoundation_HEADER_FILES_DIR)
#	cp *.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Collections.subproj/*.h $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Comm.subproj/*.h        $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Streams.subproj/*.h     $(libMPWFoundation_HEADER_FILES_DIR)
#	cp Threading.subproj/*.h   $(libMPWFoundation_HEADER_FILES_DIR)

after-clean ::
	rm -rf .headers


raspish  : libraspi
	$(CC) -g -fblocks -fobjc-runtime=gnustep-2.1 -IClasses -I/usr/GNUstep/Local/Library/Headers/ -I../Stsh/ -I../../MPWFoundation/.headers/ -I../.headers/ -I.headers -o raspish stsh_main.m -L${HOME}/Build/obj -L/usr/GNUstep/Local/Library/Libraries -lraspi -lstsh -lObjectiveSmalltalk  -lMPWFoundation -lgnustep-base -L/usr/local/lib/ -lobjc -lreadline -ledit -lmicrohttpd 
