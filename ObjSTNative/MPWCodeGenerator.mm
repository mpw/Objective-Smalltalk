//
//  MPWCodeGenerator.mm
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//

#include "llvmincludes.h"

#import "MPWCodeGenerator.h"


@implementation MPWCodeGenerator

@end

#import <MPWFoundation/MPWFoundation.h>

@interface MPWCodeGeneratorTestClass : NSObject {}  @end

@implementation MPWCodeGeneratorTestClass




@end


@implementation MPWCodeGenerator(testing)

+(void)testMessageSend
{
//    EXPECTTRUE(false, @"");
}


+testSelectors
{
    return @[ @"testMessageSend" ];
}

@end