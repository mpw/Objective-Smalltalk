//
//  STAWK.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 18.06.21.
//

#import "STAWK.h"
#import "MPWBlockContext.h"
#import "STCompiler.h"

@implementation STAWK

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    [self setSeparator:@" "];
    return self;
}

-(void)writeString:(NSString*)aString
{
    NSArray *fields=[aString componentsSeparatedByString:self.separator];
    [self.block valueWithObjects:fields];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STAWK(testing) 

+(void)testSpaceSeparatedStringsGetFilteredByBlock
{
    STCompiler *compiler=[STCompiler compiler];
    MPWByteStream *result=[MPWByteStream stream];
    STAWK *s=[STAWK stream];
    [compiler bindValue:s toVariableNamed:@"awk"];
    [compiler bindValue:result toVariableNamed:@"myout"];
    [compiler evaluateScriptString:@"awk setBlock:{ :arg1 :arg2 :arg3 | myout print:\"Arg1: {arg1} Arg3: {arg3}\". }. "];
    [s writeObject:@"Hi there how"];
    [s flush];
    IDEXPECT( [[result target] stringValue],@"Arg1: Hi Arg3: how",@"result");
}

+(NSArray*)testSelectors
{
   return @[
			@"testSpaceSeparatedStringsGetFilteredByBlock",
			];
}

@end
