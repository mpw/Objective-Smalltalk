//
//  STUITests.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.02.21.
//

#import "STUITests.h"
#import "MPWExpression.h"
#import "STTargetActionConnector.h"

@interface STTargetActionTestClass:NSObject
@end
@implementation STTargetActionTestClass

-(void)buttonAction:sender
{
    NSLog(@"button action: %@",sender);
}

@end


@implementation STUITests

+(void)testCanConnectControlToSpecificTargetViaTargetActionConnector
{
    STCompiler *compiler=[self compiler];
    NSButton* button = [compiler evaluateScriptString:@"b ← NSButton new. b."];
    EXPECTTRUE([button isKindOfClass:[NSButton class]], @"I can make buttons");
    id connector = [compiler evaluateScriptString:@"c ← STTargetActionConnector alloc initWithSelector: #buttonAction: . c."];
    EXPECTTRUE([connector isKindOfClass:[STTargetActionConnector class]], @"I can make connectors");
    id target = [compiler evaluateScriptString:@"t ← STTargetActionTestClass new. t."];
    EXPECTTRUE([target isKindOfClass:NSClassFromString(@"STTargetActionTestClass")], @"I can make instances of the target class");
    [compiler evaluateScriptString:@"b → c → t"];
    IDEXPECT( [compiler evaluateScriptString:@"c isCompatible"],@(true),@"isCompatible");
    IDEXPECT( [button target], target, @"connecting should have set the target");
    IDEXPECT( NSStringFromSelector([button action]), @"buttonAction:", @"connecting should have set the action");
}

+(void)testConvenienceTargetAction
{
    STCompiler *compiler=[self compiler];
    NSButton *b=[NSButton new];
    STTargetActionTestClass *t=[STTargetActionTestClass new];
    [compiler bindValue:b toVariableNamed:@"b"];
    [compiler bindValue:t toVariableNamed:@"t"];

    [compiler evaluateScriptString:@" b → (t actionFor: #buttonAction: )."];

    IDEXPECT( [b target], t,@"target set correctly");
    EXPECTTRUE( [b action] == @selector(buttonAction:),@"action set correctly");
}

+(void)testCanSetTextFieldParams
{
    STTargetActionTestClass *tester=[STTargetActionTestClass new];
    
    
    NSTextField *t=[NSTextField new];
    t.drawsBackground=1;
    t.selectable=1;
    STCompiler *compiler=[self compiler];
    [compiler bindValue:t toVariableNamed:@"t"];
    [compiler bindValue:tester toVariableNamed:@"tester"];
    EXPECTTRUE(t.drawsBackground, @"background drawing should be on");
    [compiler evaluateScriptString:@"t setDrawsBackground:false. "];
    
    EXPECTFALSE(t.drawsBackground, @"background drawing should be off");
    [compiler evaluateScriptString:@"t setDrawsBackground:true. "];
    EXPECTTRUE(t.drawsBackground, @"background drawing should be on");

    EXPECTTRUE(t.isSelectable, @"selectable should be on");
    [compiler evaluateScriptString:@"t setSelectable:false. "];
    EXPECTFALSE(t.isSelectable, @"selectable should be off");
}

+(NSArray*)testSelectors
{
    return @[
        @"testCanConnectControlToSpecificTargetViaTargetActionConnector",
        @"testConvenienceTargetAction",
        @"testCanSetTextFieldParams",
    ];
}
@end
