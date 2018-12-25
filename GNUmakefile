# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = ObjectiveSmalltalk

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/ObjectiveSmalltalk

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libObjectiveSmalltalk
CC = clang


OBJCFLAGS += -Wno-import -fobjc-runtime=gnustep


ObjectiveSmalltalk_HEADER_FILES = \


ObjectiveSmalltalk_HEADER_FILES_INSTALL_DIR = /ObjectiveSmalltalk


libObjectiveSmalltalk_OBJC_FILES = \
    Classes/MPWIdentifier.m \
    Classes/MPWScheme.m \
    Classes/MPWExpression.m \



libObjectiveSmalltalk_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lMPWFoundation -lgnustep-base

LDFLAGS += -L /home/gnustep/Build/MPWFoundation/obj


libObjectiveSmalltalk_INCLUDE_DIRS += -I.headers -I. -I../MPWFoundation/.headers/

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
	LD_LIBRARY_PATH=/home/gnustep/GNUstep/Library/Libraries:/usr/local/lib:/home/gnustep/Build/MPWFoundation/obj/:/home/gnustep/Build/ObjectiveSmalltalk/obj/  ./TestObjectiveSmalltalk/testobjectivesmalltalk

tester  :
	clang -fobjc-runtime=gnustep-1.9 -I../MPWFoundation/.headers/ -I.headers -o testobjectivesmalltalk/testobjectivesmalltalk testobjectivesmalltalk/testobjectivesmalltalk.m -L/home/gnustep/Build/MPWFoundation/obj -L/home/gnustep/Build/ObjectiveSmalltalk/obj -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -L/usr/local/lib/ -lobjc
