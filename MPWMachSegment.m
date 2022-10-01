//
//  MPWMachSegment.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 01.10.22.
//

#import "MPWMachSegment.h"
#import <mach-o/loader.h>

@implementation MPWMachSegment
{
    const struct segment_command_64 *segment;
}


-(instancetype)initWithSegmentPointer:(const void *)segptr
{
    if (self=[super init]) {
        segment=segptr;
    }
    return self;
}

-(int)numSections
{
    return segment->nsects;
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"

@implementation MPWMachSegment(testing) 

+(void)someTest
{
//EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
