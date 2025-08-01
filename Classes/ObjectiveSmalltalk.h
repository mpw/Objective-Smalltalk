//
//  ObjectiveSmalltalk.h>
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 27.04.20.
//

#ifndef ObjectiveSmalltalk_h
#define ObjectiveSmalltalk_h

#import <MPWFoundation/MPWFoundation.h>

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>
#import <ObjectiveSmalltalk/MPWAssignmentExpression.h>
#import <ObjectiveSmalltalk/MPWBidirectionalDataflowConstraintExpression.h>
#import <ObjectiveSmalltalk/MPWBindingLegacy.h>
#import <ObjectiveSmalltalk/MPWBlockContext.h>
#import <ObjectiveSmalltalk/MPWBlockExpression.h>
#import <ObjectiveSmalltalk/MPWBundleScheme.h>
#import <ObjectiveSmalltalk/STClassDefinition.h>
#import <ObjectiveSmalltalk/MPWClassMirror.h>
#import <ObjectiveSmalltalk/MPWComplexLiteralExpression.h>
#import <ObjectiveSmalltalk/STConnector.h>
#import <ObjectiveSmalltalk/STMessageConnector.h>
#import <ObjectiveSmalltalk/MPWDataflowConstraintExpression.h>
#import <ObjectiveSmalltalk/MPWDefaultsScheme.h>
#import <ObjectiveSmalltalk/MPWEnvScheme.h>
#import <ObjectiveSmalltalk/MPWEvaluable.h>
#import <ObjectiveSmalltalk/STEvaluator.h>
#import <ObjectiveSmalltalk/MPWExpression+autocomplete.h>
#import <ObjectiveSmalltalk/STExpression.h>
#import <ObjectiveSmalltalk/MPWFileSchemeResolver.h>
#import <ObjectiveSmalltalk/STFilterDefinition.h>
#import <ObjectiveSmalltalk/MPWFrameworkScheme.h>
#import <ObjectiveSmalltalk/MPWGlobalVariableStore.h>
#import <ObjectiveSmalltalk/MPWGetAccessor.h>
#import <ObjectiveSmalltalk/STPort.h>
#import <ObjectiveSmalltalk/STMessagePortDescriptor.h>
#import <ObjectiveSmalltalk/MPWMethodCallBack.h>
#import <ObjectiveSmalltalk/MPWMethodHeader.h>
#import <ObjectiveSmalltalk/MPWMethodMirror.h>
#import <ObjectiveSmalltalk/MPWMethodScheme.h>
#import <ObjectiveSmalltalk/MPWMethodStore.h>
#import <ObjectiveSmalltalk/MPWMethodType.h>
#import <ObjectiveSmalltalk/MPWObjectMirror.h>
//  #import <ObjectiveSmalltalk/MPWReferenceTemplate.h>
#import <ObjectiveSmalltalk/STProtocolDefinition.h>
#import <ObjectiveSmalltalk/MPWRefScheme.h>
#import <ObjectiveSmalltalk/MPWRelScheme.h>
#import <ObjectiveSmalltalk/MPWResourceScheme.h>
#import <ObjectiveSmalltalk/MPWScheme.h>
#import <ObjectiveSmalltalk/MPWSchemeScheme.h>
#import <ObjectiveSmalltalk/STScriptedMethod.h>
#import <ObjectiveSmalltalk/MPWScriptingBridgeScheme.h>
#import <ObjectiveSmalltalk/MPWSelfContainedBindingsScheme.h>
#import <ObjectiveSmalltalk/MPWSetAccessor.h>
#import <ObjectiveSmalltalk/MPWSpotlightScheme.h>
#import <ObjectiveSmalltalk/STCompiler.h>
#import <ObjectiveSmalltalk/MPWTreeNodeScheme.h>
#import <ObjectiveSmalltalk/MPWStatementList.h>
//#import <ObjectiveSmalltalk/MPWURLBinding.h>
//#import <ObjectiveSmalltalk/MPWURLSchemeResolver.h>
#import <ObjectiveSmalltalk/MPWVARBinding.h>
#import <ObjectiveSmalltalk/MPWVarScheme.h>
#import <ObjectiveSmalltalk/NSObjectScripting.h>
#import <ObjectiveSmalltalk/STBundle.h>
#import <ObjectiveSmalltalk/STVariableDefinition.h>
#import <ObjectiveSmalltalk/ViewBuilderPreviewNotification.h>
#ifndef TARGET_OS_IPHONE
#import <ObjectiveSmalltalk/STProgram.h>
#import <ObjectiveSmalltalk/STJittableData.h>
#endif

#endif /* ObjectiveSmalltalk_h */
