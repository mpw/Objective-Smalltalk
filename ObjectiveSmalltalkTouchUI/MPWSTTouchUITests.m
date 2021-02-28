//
//  MPWSTTouchUITests.m
//  ObjectiveSmalltalkTouchUI
//
//  Created by Marcel Weiher on 28.02.21.
//

#import "MPWSTTouchUITests.h"
#import "MPWFontStore.h"
#import <UIKit/UIKit.h>
#import "STTargetActionConnector.h"


@interface STTargetActionTestClass:NSObject
@end
@implementation STTargetActionTestClass

-(void)buttonAction:sender
{
    NSLog(@"button action: %@",sender);
}

@end


@implementation MPWSTTouchUITests

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSTTouchUITests(testing) 

+(void)testGetFontViaStore
{
    MPWFontStore *fonts=[MPWFontStore store];
    UIFont *f=[fonts at:@"Helvetica/12"];
    FLOATEXPECT(f.pointSize, 12, @"font size");
    IDEXPECT(f.fontName, @"Helvetica", @"font name");
}


+(void)testCanConnectControlToSpecificTargetViaTargetActionConnector
{
    STCompiler *compiler=[self compiler];
    UIButton* button = [compiler evaluateScriptString:@"b ← UIButton new. b."];
    EXPECTTRUE([button isKindOfClass:[UIButton class]], @"I can make buttons");
    id connector = [compiler evaluateScriptString:@"c ← STTargetActionConnector alloc initWithSelector: #buttonAction: . c."];
    EXPECTTRUE([connector isKindOfClass:[STTargetActionConnector class]], @"I can make connectors");
    id target = [compiler evaluateScriptString:@"t ← STTargetActionTestClass new. t."];
    EXPECTTRUE([target isKindOfClass:NSClassFromString(@"STTargetActionTestClass")], @"I can make instances of the target class");
    [compiler evaluateScriptString:@"b → c → t"];
    EXPECTTRUE([connector isCompatible], @"isCompatible after connect attempt");
    IDEXPECT( [compiler evaluateScriptString:@"c isCompatible"],@(true),@"isCompatible");
    IDEXPECT( [button allTargets].anyObject, target, @"connecting should have set the target");
//    IDEXPECT( NSStringFromSelector([button action]), @"buttonAction:", @"connecting should have set the action");
}


+(NSArray*)testSelectors
{
   return @[
       @"testGetFontViaStore",
       @"testCanConnectControlToSpecificTargetViaTargetActionConnector",
			];
}

@end
