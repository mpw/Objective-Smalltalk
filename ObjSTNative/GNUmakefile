# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.m \ake

FRAMEWORK_NAME = ObjSTNative

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.m \ake
GNUSTEP_BUILD_DIR = ~/Build/

include $(GNUSTEP_MAKEFILES)/common.m \ake


LIBRARY_NAME = libObjSTNative


OBJCFLAGS += -g -Os -Wno-import 


ObjectiveSmalltalk_HEADER_FILES = \


ObjectiveSmalltalk_HEADER_FILES_INSTALL_DIR = /ObjSTNative


libObjectiveSmalltalk_OBJC_FILES = \
	MPWARMObjectCodeGenerator.m \ 
	MPWByteStreamWithSymbols.m \
	MPWCPUSimulator.m \
	MPWELFReader.m \
	MPWELFSection.m \
	MPWELFSectionWriter.m \
	MPWELFSymbolTable.m \
	MPWELFWriter.m \
	MPWJittableData.m \
	MPWMachOClassReader.m \
	MPWMachOClassWriter.m \
	MPWMachOInSectionPointer.m \
	MPWMachOReader.m \
	MPWMachORelocationPointer.m \
	MPWMachOSection.m \
	MPWMachOSectionWriter.m \
	MPWMachOWriter.m \
	MPWMethodDescriptor.m \
	MPWObjectFileWriter.m \
	MPWStringTableWriter.m \
	STMethodSymbols.m \
	STNativeCompiler.m \



libObjectiveSmalltalk_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lMPWFoundation -lgnustep-base -lgnustep-corebase

LDFLAGS += -L ${HOME}/Build/obj -L ~/Build/obj


libObjectiveSmalltalk_INCLUDE_DIRS += -I.headers -I. -I../MPWFoundation/.headers/

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.m \ake
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

