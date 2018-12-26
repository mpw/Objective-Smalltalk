# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = stsh

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/stsh

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libstsh
CC = clang


OBJCFLAGS += -Wno-import -fobjc-runtime=gnustep


stsh_HEADER_FILES = \


stsh_HEADER_FILES_INSTALL_DIR = /stsh


libstsh_OBJC_FILES = \
    Classes/MPWStScript.m \
    Classes/MPWStsh.m \
    Classes/MPWShellCompiler.m \
    MPWShellPrinter.m \


libstsh_C_FILES = \




LIBRARIES_DEPEND_UPON += -lObjectiveSmalltalk  -lMPWFoundation -lgnustep-base

LDFLAGS += -L /home/gnustep/Build/MPWFoundation/obj -L /home/gnustep/Build/ObjectiveSmalltalk/obj


libstsh_INCLUDE_DIRS += -I.headers -I. -I../../MPWFoundation/.headers/ -I../.headers/

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


# stsh    : libstsh tester
#	LD_LIBRARY_PATH=/home/gnustep/GNUstep/Library/Libraries:/usr/local/lib:/home/gnustep/Build/MPWFoundation/obj/:/home/gnustep/Build/ObjectiveSmalltalk/obj/:/home/gnustep/Build/stsh/obj/ ./TestObjectiveSmalltalk/testobjectivesmalltalk

stsh  : libstsh
	clang -fblocks -fobjc-runtime=gnustep-1.9 -I../../MPWFoundation/.headers/ -I.headers -o stsh stsh_main.m -L/home/gnustep/Build/MPWFoundation/obj -L/home/gnustep/Build/ObjectiveSmalltalk/obj -L/home/gnustep/Build/stsh/obj -lstsh -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -L/usr/local/lib/ -lobjc -lreadline -ledit
