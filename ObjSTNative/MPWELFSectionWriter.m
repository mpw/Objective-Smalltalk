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

-(int)alignment
{
    return 8;
}

-(int)padding
{
    NSLog(@"padding: alignment=%d",self.alignment);
    int leftover = self.sectionData.length % self.alignment;
    NSLog(@"leftover=%d",leftover);
    int pad = leftover > 0 ? self.alignment - leftover : 0;
    NSLog(@"pad=%d",pad);
    return pad;

}

-(long)sectionLength
{
    return self.sectionData.length + self.padding;
}


-(void)writeSctionHeaderOnWriter:(MPWByteStream*)writer
{
    Elf64_Shdr sectionHeader={0};
    sectionHeader.sh_name = [self nameIndex];
    sectionHeader.sh_type = self.sectionType;
    sectionHeader.sh_offset = self.sectionOffset;
    sectionHeader.sh_size = self.sectionLength;
    [writer appendBytes:&sectionHeader length:sizeof sectionHeader];
}

-(void)writeSectionDataOnWriter:(MPWByteStream*)writer
{
    const char paddingData[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    NSLog(@"write %ld bytes of section data (padded: %ld) for section %d",self.sectionData.length,self.sectionLength,self.sectionNumber);
    [writer appendBytes:self.sectionData.bytes length:self.sectionData.length];
    NSLog(@"write %d bytes of padding",self.padding);
    [writer appendBytes:paddingData length:self.padding];
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
