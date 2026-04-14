//
//  STMultiSymbolCounter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.04.26.
//

#import "STMultiSymbolCounter.h"
#import "STSymbolCounter.h"

@implementation STMultiSymbolCounter

-init {
    self = [super init];
    self.counters = [NSMutableDictionary dictionary];
    return self;
}

-(STSymbolCounter*)counterForString:(NSString*)string
{
    STSymbolCounter *counter=self.counters[string];
    if ( !counter )  {
        counter = [STSymbolCounter counterWithTemplate:[string stringByAppendingString:@"_%d"]];
        self.counters[string]=counter;
    }
    return counter;
}

-(NSString*)nextSymbolForTemplate:(NSString *)string
{
    return [[self counterForString:string] nextObject];
}

-(void)dealloc
{
    [_counters release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STMultiSymbolCounter(testing) 

+(void)testGetSomeSymbols
{
    STMultiSymbolCounter *counter=[[self new] autorelease];
    IDEXPECT([counter nextSymbolForTemplate:@"_BASE_TEMPLATE"],@"_BASE_TEMPLATE_0",@"first");
    IDEXPECT([counter nextSymbolForTemplate:@"_BASE_TEMPLATE"],@"_BASE_TEMPLATE_1",@"second");
    IDEXPECT([counter nextSymbolForTemplate:@"_OTHER_TEMPLATE"],@"_OTHER_TEMPLATE_0",@"first of second");
    IDEXPECT([counter nextSymbolForTemplate:@"_BASE_TEMPLATE"],@"_BASE_TEMPLATE_2",@"third");
    IDEXPECT([counter nextSymbolForTemplate:@"_OTHER_TEMPLATE"],@"_OTHER_TEMPLATE_1",@"second of second");
}

+(NSArray*)testSelectors
{
   return @[
			@"testGetSomeSymbols",
			];
}

@end
