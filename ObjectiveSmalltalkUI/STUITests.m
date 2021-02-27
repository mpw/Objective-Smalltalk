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

+(void)testConvenienceTargetActionViaPort
{
    STCompiler *compiler=[self compiler];
    NSButton *b=[NSButton new];
    STTargetActionTestClass *t=[STTargetActionTestClass new];
    [compiler bindValue:b toVariableNamed:@"b"];
    [compiler bindValue:t toVariableNamed:@"t"];
    
    [compiler evaluateScriptString:@" b → t portFor: #buttonAction:."];
    IDEXPECT( [b target], t,@"target set correctly");
    EXPECTTRUE( [b action] == @selector(buttonAction:),@"action set correctly");
}

+(void)testConvenienceTargetActionViaPortSchemeForTarget
{
    STCompiler *compiler=[self compiler];
    NSButton *b=[NSButton new];
    STTargetActionTestClass *t=[STTargetActionTestClass new];
    [compiler bindValue:b toVariableNamed:@"b"];
    [compiler bindValue:t toVariableNamed:@"t"];
    
    [compiler evaluateScriptString:@" b → port:t/buttonAction: ."];
    IDEXPECT( [b target], t,@"target set correctly");
    EXPECTTRUE( [b action] == @selector(buttonAction:),@"action set correctly");
}

+(void)testCanSetBooleanTextFieldParams
{
    NSTextField *t=[NSTextField new];
    t.drawsBackground=1;
    t.selectable=1;
    STCompiler *compiler=[self compiler];
    [compiler bindValue:t toVariableNamed:@"t"];
    EXPECTTRUE(t.drawsBackground, @"background drawing should be on");
    IDEXPECT([compiler evaluateScriptString:@"t drawsBackground. "],@(true), @"background drawing should be on");
    [compiler evaluateScriptString:@"t setDrawsBackground:false. "];
    EXPECTFALSE(t.drawsBackground, @"background drawing should be off");
    IDEXPECT([compiler evaluateScriptString:@"t drawsBackground. "],@(false), @"background drawing should be off");
    

    [compiler evaluateScriptString:@"t setDrawsBackground:true. "];
    EXPECTTRUE(t.drawsBackground, @"background drawing should be on");
    IDEXPECT([compiler evaluateScriptString:@"t drawsBackground. "],@(true), @"background drawing should be on");

    EXPECTTRUE(t.isSelectable, @"selectable should be on");
    [compiler evaluateScriptString:@"t setSelectable:false. "];
    EXPECTFALSE(t.isSelectable, @"selectable should be off");
    IDEXPECT([compiler evaluateScriptString:@"t isSelectable. "],@(false), @"selectable should be off");
    
}

+(NSArray*)testSelectors
{
    return @[
        @"testCanConnectControlToSpecificTargetViaTargetActionConnector",
        @"testConvenienceTargetAction",
        @"testConvenienceTargetActionViaPort",
        @"testCanSetBooleanTextFieldParams",
//        @"testConvenienceTargetActionViaPortSchemeForTarget",
    ];
}
@end


@implementation NSTextField(debug)

-(void)dumpOn:(MPWByteStream*)aStream
{
    [aStream printFormat:@"<%s:%p: ",object_getClassName(self),self];
    [aStream printFormat:@"frame: %@ ",NSStringFromRect(self.frame)];
    [aStream printFormat:@"stringValue: %@ ",self.stringValue];
    [aStream printFormat:@"textColor: %@ ",self.textColor];
    [aStream printFormat:@"backGroundColor: %@ ",self.backgroundColor];
    [aStream printFormat:@"drawsBackground: %d ",self.drawsBackground];
    [aStream printFormat:@"isBordered: %d ",self.isBordered];
    [aStream printFormat:@"isSelectable: %d ",self.isSelectable];
    [aStream printFormat:@"isOpaque: %d",self.isOpaque];

    [aStream printFormat:@">\n"];
}



@end


@implementation NSControl(streaming)

-defaultInputPort
{
    return [[[STMessagePortDescriptor alloc] initWithTarget:self key:nil protocol:@protocol(Streaming) sends:NO] autorelease];
}


-(void)writeObject:anObject
{
    self.objectValue = anObject;
}

-(void)appendBytes:(const void*)bytes length:(long)len
{
    self.stringValue = [NSString stringWithCString:bytes length:len];
}

@end
