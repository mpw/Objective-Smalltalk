# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = stsh

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libstsh
CC = clang


OBJCFLAGS += -Wno-import -fobjc-runtime=gnustep


stsh_HEADER_FILES = \


stsh_HEADER_FILES_INSTALL_DIR = /stsh


libstsh_OBJC_FILES = \
    Classes/MPWStScript.m \
    Classes/MPWStsh.m \
    Classes/MPWEchoCommand.m \
    Classes/MPWShellCompiler.m \
    Classes/MPWExternalCommand.m \
    Classes/MPWCommandFilter.m \
    Classes/MPWObjectPipeCommand.m \
    Classes/MPWUpcaseFilter.m \
    Classes/MPWAbstractShellCommand.m \
    Classes/MPWShellProcess.m \
    MPWShellPrinter.m \


libstsh_C_FILES = \




LIBRARIES_DEPEND_UPON += -lObjectiveSmalltalk  -lMPWFoundation -lgnustep-base

LDFLAGS += -L /home/gnustep/Build/obj


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
#	LD_LIBRARY_PATH=/home/gnustep/GNUstep/Library/Libraries:/usr/local/lib:/home/gnustep/Build/obj/ ./TestObjectiveSmalltalk/testobjectivesmalltalk

stsh  : libstsh
	clang -fblocks -fobjc-runtime=gnustep-1.9 -I../../MPWFoundation/.headers/ -I.headers -o stsh stsh_main.m -L/home/gnustep/Build/obj -lstsh -lObjectiveHTTPD -lObjectiveSmalltalk -lMPWXmlKit -lMPWFoundation -lgnustep-base -L/usr/local/lib/ -lobjc -lreadline -ledit -lmicrohttpd
