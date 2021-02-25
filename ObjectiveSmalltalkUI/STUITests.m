//
//  STUITests.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.02.21.
//

#import "STUITests.h"
#import "MPWExpression.h"
#import "STTargetActionConnector.h"



@implementation STUITests

+(void)testCanConnectControlToSpecificTargetViaTargetActionConnector
{
    STCompiler *compiler=[self compiler];
    NSButton* button = [compiler evaluateScriptString:@"b ← NSButton new. b."];
    EXPECTTRUE([button isKindOfClass:[NSButton class]], @"I can make buttons");
    id connector = [compiler evaluateScriptString:@"c ← STTargetActionConnector alloc initWithSelector: #buttonAction: . c."];
    EXPECTTRUE([connector isKindOfClass:[STTargetActionConnector class]], @"I can make connectors");
    [compiler evaluateScriptString:@"class STTargetActionTestClass  { -<void>buttonAction:sender { stdout println:sender stringValue. } }"];
    id target = [compiler evaluateScriptString:@"t ← STTargetActionTestClass new. t."];
    EXPECTTRUE([target isKindOfClass:NSClassFromString(@"STTargetActionTestClass")], @"I can make instances of the target class");
    [compiler evaluateScriptString:@"b → c → t"];
    IDEXPECT( [compiler evaluateScriptString:@"c isCompatible"],@(true),@"isCompatible");
    IDEXPECT( [button target], target, @"connecting should have set the target");
    IDEXPECT( NSStringFromSelector([button action]), @"buttonAction:", @"connecting should have set the action");
}

+(NSArray*)testSelectors
{
    return @[
        @"testCanConnectControlToSpecificTargetViaTargetActionConnector",
    ];
}
@end
