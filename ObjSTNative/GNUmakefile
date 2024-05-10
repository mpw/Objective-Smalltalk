# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = ObjSTNative

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libObjSTNative


OBJCFLAGS += -g -Os -Wno-import 


ObjSTNative_HEADER_FILES = \


ObjSTNative_HEADER_FILES_INSTALL_DIR = /ObjSTNative


libObjSTNative_OBJC_FILES = \
	MPWByteStreamWithSymbols.m \
	MPWCPUSimulator.m \
	MPWELFReader.m \
	MPWELFSection.m \
	MPWELFSectionWriter.m \
	MPWELFSymbolTable.m \
	MPWELFWriter.m \
	MPWJittableData.m \
	MPWMethodDescriptor.m \
	MPWObjectFileWriter.m \
	MPWStringTableWriter.m \
	STMethodSymbols.m \



libObjSTNative_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lMPWFoundation -lgnustep-base -lgnustep-corebase

LDFLAGS += -L ${HOME}/Build/obj -L ~/Build/obj


libObjSTNative_INCLUDE_DIRS += -Imacho-headers -I.headers -I. -I../.headers/ -I../../MPWFoundation/.headers/

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

test    : libObjSTNative tester
	LD_LIBRARY_PATH=/usr/GNUstep/Local/Library/Libraries:/usr/local/lib:${HOME}/Build/obj/  ./testelfnative


tester  :
	$(CC) -g -fobjc-runtime=gnustep-2.1 -fblocks -I../../MPWFoundation/.headers/ -I../.headers -I.headers -I/usr/GNUstep/Local/Library/Headers/ -o testelfnative testelfnative.m -L/usr/GNUstep/Local/Library/Libraries/ -L ${HOME}/Build/obj/ -lObjSTNative -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc

