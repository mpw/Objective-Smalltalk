# $Id: GNUmakefile,v 1.11 2004/12/08 21:20:43 marcel Exp $


OBJC_RUNTIME_LIB=ng

#include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = ObjectiveSmalltalk

GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
GNUSTEP_BUILD_DIR = ~/Build/

include $(GNUSTEP_MAKEFILES)/common.make


LIBRARY_NAME = libObjectiveSmalltalk


OBJCFLAGS += -g -Os -Wno-import 


ObjectiveSmalltalk_HEADER_FILES = \


ObjectiveSmalltalk_HEADER_FILES_INSTALL_DIR = /ObjectiveSmalltalk


libObjectiveSmalltalk_OBJC_FILES = \
    Classes/STIdentifier.m \
    Classes/MPWScheme.m \
	Classes/STPropertyMethodHeader.m \
    Classes/STExpression.m \
    Stsh/Classes/MPWExpression+autocomplete.m \
    Classes/MPWBindingLegacy.m \
    Classes/STScanner.m \
    Classes/MPWMessage.m \
    Classes/MPWMessage.m \
    Classes/MPWSelfContainedBinding.m \
    Classes/MPWClassMirror.m \
    Classes/MPWObjectMirror.m \
    Classes/MPWMethodMirror.m \
    Classes/STEvaluator.m \
    Classes/MPWMessageExpression.m \
    Classes/MPWRecursiveIdentifier.m \
    Classes/STFilterDefinition.m \
    Classes/MPWBidirectionalDataflowConstraintExpression.m \
    Classes/STIdentifierExpression.m \
    Classes/STScriptedMethod.m \
    Classes/MPWMethodHeader.m \
    Classes/MPWLiteralExpression.m \
    Classes/MPWComplexLiteralExpression.m \
    Classes/MPWFastMessage.m \
    Classes/MPWFastSuperMessage.m \
    Classes/MPWInstanceVariable.m \
    Classes/MPWLiteralArrayExpression.m \
    Classes/STProtocolDefinition.m \
    Classes/MPWBlockExpression.m \
    Classes/MPWAssignmentExpression.m \
    Classes/STPostExpression.m \
    Classes/STQueryExpression.m \
    Classes/MPWStatementList.m \
    Classes/MPWDataflowConstraintExpression.m \
    Classes/MPWLiteralDictionaryExpression.m \
    Classes/STPort.m \
    Classes/STSystem.m \
    Classes/STConnectionDefiner.m \
    Classes/STClassDefinition.m \
    Classes/MPWMethodStore.m \
    Classes/MPWObjCGenerator.m \
    Classes/STPropertyPathDefinition.m \
    Classes/STConnector.m \
    Classes/STConnectionDefinition.m \
    Classes/STNotificationDefinition.m \
    Classes/STSimpleDataflowConstraint.m \
    Classes/MPWMethodType.m \
    Classes/MPWPropertyPathMethod.m \
    Classes/MPWBlockContext.m \
    Classes/MPWAbstractInterpretedMethod.m \
    Classes/MPWClassMethodStore.m \
    Classes/STMessagePortDescriptor.m \
    Classes/MPWMethodCallBack.m \
    Classes/STCompiler.m \
    Classes/NSObjectScripting.m \
    Classes/MPWGetAccessor.m \
    Classes/MPWSetAccessor.m \
    Classes/STBundle.m \
    Classes/STMessageConnector.m \
    Classes/STObjectTemplate.m \
    Classes/STSubscriptExpression.m \
    Classes/STVariableDefinition.m \
    Classes/STTypeDescriptor.m \
    MPWCascadeExpression.m \
    Schemes/MPWDyLibScheme.m \
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
    Schemes/MPWEnvScheme.m \
    Schemes/MPWRelScheme.m \
    Schemes/MPWTreeNodeScheme.m \
    Schemes/MPWTreeNode.m \
    Schemes/MPWBlockFilterScheme.m \
    Schemes/STPortScheme.m \
    Schemes/STProtocolScheme.m \
    Schemes/MPWGlobalVariableStore.m \
    Tests/STTests.m \



libObjectiveSmalltalk_C_FILES = \




LIBRARIES_DEPEND_UPON +=  -lMPWFoundation -lgnustep-base -lgnustep-corebase

LDFLAGS += -L ${HOME}/Build/obj -L ~/Build/obj


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
	LD_LIBRARY_PATH=/usr/GNUstep/Local/Library/Libraries:/usr/local/lib:${HOME}/Build/obj/  ./TestObjectiveSmalltalk/testobjectivesmalltalk

tester  :
	$(CC) -g -fobjc-runtime=gnustep-2.1 -fblocks -I../MPWFoundation/.headers/ -I.headers -I/usr/GNUstep/Local/Library/Headers/ -o TestObjectiveSmalltalk/testobjectivesmalltalk TestObjectiveSmalltalk/testobjectivesmalltalk.m -L/usr/GNUstep/Local/Library/Libraries/ -L ${HOME}/Build/obj/  -lObjectiveSmalltalk -lMPWFoundation -lgnustep-base -lgnustep-corebase -L/usr/local/lib/ -lobjc
