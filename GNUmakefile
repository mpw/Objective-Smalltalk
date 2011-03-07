# $Id: GNUmakefile,v 1.1 2005/02/16 11:13:50 marcel Exp $


GNUSTEP_LOCAL_ADDITIONAL_MAKEFILES=base.make
include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libMPWTalk

libMPWTalk_DLL_DEF = MPWPDFInterpreter.def
libMPWTalk_LIBRARIES_DEPEND_UPON += -lMPWFoundation -lgnustep-base -lobjc
 
libMPWTalk_INCLUDE_DIRS += -I.headers -I. -I..

 
libMPWTalk_OBJC_FILES = \
	MPWAssignmentExpression.m \
	MPWBinding.m \
	MPWBlockContext.m \
	MPWBlockExpression.m \
	MPWEvaluator.m \
	MPWExpression.m \
	MPWInterval.m \
	MPWMessage.m \
	MPWMessageExpression.m \
	MPWStCompiler.m \
	MPWStScanner.m \
	MPWStatementList.m \
	MPWVariableExpression.m \
 
libMPWTalk_HEADER_FILES = \
	MPWAssignmentExpression.h \
	MPWBinding.h \
	MPWBlockContext.h \
	MPWBlockExpression.h \
	MPWEvaluator.h \
	MPWExpression.h \
	MPWInterval.h \
	MPWMessage.h \
	MPWMessageExpression.h \
	MPWStCompiler.h \
	MPWStScanner.h \
	MPWStatementList.h \
	MPWVariableExpression.h \
 
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble
