//
//  STSymbolCounter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.04.26.
//

#import "STSymbolCounter.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation STSymbolCounter
{
    int count;
}

CONVENIENCEANDINIT(counter, WithTemplate:(NSString*)newTemplate)
{
    self=[super init];
    self.template = newTemplate;
    return self;
}

-nextObject
{
    return [NSString stringWithFormat:self.template,count++];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STSymbolCounter(testing) 

+(void)testGeneration
{
    STSymbolCounter *counter=[self counterWithTemplate:@"MACHO_SYMBOL_%d"];
    IDEXPECT([counter nextObject],@"MACHO_SYMBOL_0",@"first symbol");
    IDEXPECT([counter nextObject],@"MACHO_SYMBOL_1",@"second symbol");
}

+(NSArray*)testSelectors
{
   return @[
			@"testGeneration",
			];
}

@end
