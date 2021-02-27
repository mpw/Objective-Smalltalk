//
//  STTargetActionSenderPort.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 26.02.21.
//

#import "STTargetActionSenderPort.h"
#import "STTargetActionConnector.h"

@interface STTargetActionSenderPort()

@property (strong,nonatomic) NSControl *control;

@end
@implementation STTargetActionSenderPort


-(BOOL)sendsMessages
{
    return YES;
}


-initWithControl:aControl
{
    self=[super init];
    self.control=aControl;
    return self;
}

-(id)targetObject
{
    return self.control;
}

-(BOOL)receivesMessages
{
    return ![self sendsMessages];
}


-(BOOL)connect:(STMessagePortDescriptor*)other
{
    STTargetActionConnector *connector=[[[STTargetActionConnector alloc] initWithSelector:other.message] autorelease];
    connector.source=(id)self;
    connector.target=other;
    if ( other.messageProtocol == @protocol(Streaming) ) {
        connector.message = @selector(writeTarget:);
    }
    return [connector connect];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTargetActionSenderPort(testing) 

+(void)testConnectTextFieldToStream
{
    STCompiler *compiler=[STCompiler compiler];
    NSTextField *textfield=[[NSTextField new] autorelease];
    NSMutableString *result=[NSMutableString string];
    MPWByteStream *stream=[MPWByteStream streamWithTarget:result];
    [compiler bindValue:textfield toVariableNamed:@"textfield"];
    [compiler bindValue:stream toVariableNamed:@"stream"];
    [compiler evaluateScriptString:@"textfield → stream."];
    EXPECTNOTNIL( textfield.target, @"textfield should now have a target");
    [textfield setStringValue:@"test"];
    IDEXPECT( result, @"", @"should be empty before sending action");
    [textfield sendAction:textfield.action to:textfield.target];
    IDEXPECT( result, @"test", @"now have the action");

}

+(NSArray*)testSelectors
{
   return @[
			@"testConnectTextFieldToStream",
			];
}

@end
