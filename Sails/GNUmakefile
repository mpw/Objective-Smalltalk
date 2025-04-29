# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = Sails

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libSails


OBJCFLAGS += -g -Os -Wno-import 


libSails_OBJC_FILES = \
	Code/STEntity.m \
	Code/STEntityList.m \
	Code/STHypertextProcessor.m \
	Code/STPathToTemplateNameMapper.m \
	Code/STRootMapper.m \
	Code/STSiteBundle.m \
	Code/STSiteServer.m \
	Code/STTemplateStore.m \
	Code/SailsGenerator.m \


Sails_HEADER_FILES = \


Sails_HEADER_FILES_INSTALL_DIR = /Sails



libSails_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -lgnustep-corebase

LDFLAGS += -L ${HOME}/Build/obj -L ~/Build/obj


libSails_INCLUDE_DIRS += -I.headers -I. -I../../MPWFoundation/.headers/ -I../.headers/

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


test    : libObjectiveSmalltalk tester
	LD_LIBRARY_PATH=/usr/GNUstep/Local/Library/Libraries:/usr/local/lib:${HOME}/Build/obj/  ./TestObjectiveSmalltalk/testobjectivesmalltalk

tester  :
	$(CC) -g -fobjc-runtime=gnustep-2.1 -fblocks -I../MPWFoundation/.headers/ -I.headers -I/usr/GNUstep/Local/Library/Headers/ -o TestObjectiveSmalltalk/testobjectivesmalltalk TestObjectiveSmalltalk/testobjectivesmalltalk.m -L/usr/GNUstep/Local/Library/Libraries/ -L ${HOME}/Build/obj/  -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc
