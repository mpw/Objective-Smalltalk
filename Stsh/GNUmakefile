# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = stsh

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libstsh


OBJCFLAGS += -g -Os -Wno-import 


stsh_HEADER_FILES = \


stsh_HEADER_FILES_INSTALL_DIR = /stsh


libstsh_OBJC_FILES = \
    Classes/STScript.m \
    Classes/STShell.m \
    Classes/MPWEchoCommand.m \
    Classes/MPWShellCompiler.m \
    Classes/MPWExternalCommand.m \
    Classes/MPWCommandFilter.m \
    Classes/MPWCommandStore.m \
    Classes/MPWCommandBinding.m \
    Classes/MPWObjectPipeCommand.m \
    Classes/MPWUpcaseFilter.m \
    Classes/MPWAbstractShellCommand.m \
    Classes/MPWShellProcess.m \
    MPWShellPrinter.m \


libstsh_C_FILES = \




LIBRARIES_DEPEND_UPON += -lObjectiveSmalltalk  -lMPWFoundation -lgnustep-base

LDFLAGS += -L ${HOME}/Build/obj 


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


stsh  : libstsh
	$(CC) -g -fobjc-runtime=gnustep-2.1  -fblocks -IClasses -I/usr/GNUstep/Local/Library/Headers/  -I../../MPWFoundation/.headers/ -I.headers -o stsh stsh_main.m -L ${HOME}/Build/obj -L/usr/GNUstep/Local/Library/Libraries -lstsh  -lObjectiveSmalltalk -lObjectiveHTTPD -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc -lreadline -ledit -lmicrohttpd
