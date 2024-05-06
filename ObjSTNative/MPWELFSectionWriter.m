//
//  MPWELFSectionWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import "MPWELFSectionWriter.h"
#import "elf.h"

@interface MPWELFSectionWriter()



@end


@implementation MPWELFSectionWriter

-(int)nameIndex
{
    return 0;
}

-(void)writeSctioHeaderOnWriter:(MPWByteStream*)writer
{
    Elf64_Shdr sectionHeader={0};
    sectionHeader.sh_name = [self nameIndex];
    sectionHeader.sh_type = self.sectionType;
    [writer appendBytes:&sectionHeader length:sizeof sectionHeader];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFSectionWriter(testing) 

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
