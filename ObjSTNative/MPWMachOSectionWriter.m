//
//  MPWMachOSectionWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import "MPWMachOSectionWriter.h"
#import "MPWMachOWriter.h"
#import <mach-o/loader.h>

@implementation MPWMachOSectionWriter


-(void)writeSectionLoadCommandOnWriter:(MPWMachOWriter*)writer offset:(long)offset
{
    struct section_64 textSection={};
    strcpy( textSection.sectname, "__text");
    strcpy( textSection.segname, "__TEXT");
    textSection.offset = offset;
    textSection.size = self.length;
    textSection.flags = S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS;
    textSection.nreloc = [writer numRelocationEntries];
    textSection.reloff = [writer relocationEntriessOffset];
    [writer appendBytes:&textSection length:sizeof textSection];

}

-(NSData*)data
{
    return [self target];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOSectionWriter(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
