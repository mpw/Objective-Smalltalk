# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = ObjectiveSmalltalk

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libObjectiveSmalltalk
CC = clang


OBJCFLAGS += -g -Os -Wno-import -fobjc-runtime=gnustep-2  -fmodules -fmodules -fmodules-cache-path=/home/gnustep/Build/Modules 


ObjectiveSmalltalk_HEADER_FILES = \


ObjectiveSmalltalk_HEADER_FILES_INSTALL_DIR = /ObjectiveSmalltalk


libObjectiveSmalltalk_OBJC_FILES = \
    Classes/MPWIdentifier.m \
    Classes/MPWScheme.m \
    Classes/MPWExpression.m \
    Classes/MPWBinding.m \
    Classes/MPWStScanner.m \
    Classes/MPWMessage.m \
    Classes/MPWMessage.m \
    Classes/MPWSelfContainedBinding.m \
    Classes/MPWClassMirror.m \
    Classes/MPWObjectMirror.m \
    Classes/MPWMethodMirror.m \
    Classes/MPWEvaluator.m \
    Classes/MPWMessageExpression.m \
    Classes/MPWRecursiveIdentifier.m \
    Classes/MPWFilterDefinition.m \
    Classes/MPWBidirectionalDataflowConstraintExpression.m \
    Classes/MPWIdentifierExpression.m \
    Classes/MPWScriptedMethod.m \
    Classes/MPWMethodHeader.m \
    Classes/MPWLiteralExpression.m \
    Classes/MPWInstanceVariable.m \
    Classes/MPWLiteralArrayExpression.m \
    Classes/MPWPropertyPathComponent.m \
    Classes/MPWProtocolDefinition.m \
    Classes/MPWBlockExpression.m \
    Classes/MPWAssignmentExpression.m \
    Classes/MPWStatementList.m \
    Classes/MPWDataflowConstraintExpression.m \
    Classes/MPWLiteralDictionaryExpression.m \
    Classes/MPWConnectToDefault.m \
    Classes/MPWClassDefinition.m \
    Classes/MPWComplexAssignment.m \
    Classes/MPWPropertyPath.m \
    Classes/MPWMethodStore.m \
    Classes/MPWObjCGenerator.m \
    Classes/MPWPropertyPathDefinition.m \
    Classes/MPWConnector.m \
    Classes/MPWMethodType.m \
    Classes/MPWPropertyPathGetter.m \
    Classes/MPWPropertyPathSetter.m \
    Classes/MPWBlockContext.m \
    Classes/MPWAbstractInterpretedMethod.m \
    Classes/MPWClassMethodStore.m \
    Classes/MPWMessagePortDescriptor.m \
    Classes/MPWMethodCallBack.m \
    Classes/MPWResource.m \
    Classes/MPWStCompiler.m \
    Classes/MPWStTests.m \
    Classes/NSObjectScripting.m \
    Classes/MPWGetAccessor.m \
    Classes/MPWSetAccessor.m \
    Classes/STBundle.m \
    MPWCascadeExpression.m \
    Schemes/MPWRefScheme.m \
    Schemes/MPWClassScheme.m \
    Schemes/MPWFrameworkScheme.m \
    Schemes/MPWSchemeScheme.m \
    Schemes/MPWVarScheme.m \
    Schemes/MPWVARBinding.m \
    Schemes/MPWSelfContainedBindingsScheme.m \
    Schemes/MPWBundleScheme.m \
    Schemes/MPWFileSchemeResolver.m \
    Schemes/MPWDefaultsScheme.m \
    Schemes/MPWURLSchemeResolver.m \
    Schemes/MPWEnvScheme.m \
    Schemes/MPWRelScheme.m \
    Schemes/MPWTreeNodeScheme.m \
    Schemes/MPWTreeNode.m \
    Schemes/MPWBlockFilterScheme.m \



# Classes/MPWStTests.m \
# Classes/MPWStCompiler.m \



libObjectiveSmalltalk_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lMPWFoundation -lgnustep-base

LDFLAGS += -L /home/gnustep/Build/obj


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
	LD_LIBRARY_PATH=/home/gnustep/GNUstep/Library/Libraries:/usr/local/lib:/home/gnustep/Build/obj/  ./TestObjectiveSmalltalk/testobjectivesmalltalk

tester  :
	clang -g -fobjc-runtime=gnustep-2 -I../MPWFoundation/.headers/ -I.headers -o testobjectivesmalltalk/testobjectivesmalltalk testobjectivesmalltalk/testobjectivesmalltalk.m -L/home/gnustep/Build/obj  -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -L/usr/local/lib/ -lobjc
