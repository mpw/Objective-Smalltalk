//
//  MPWELFWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 05.05.24.
//

#import "MPWELFWriter.h"
#import "elf.h"

@implementation MPWELFWriter


-(void)writeHeader
{
    Elf64_Ehdr header={ELFMAG};
    header.e_type = ET_REL;
    header.e_machine = EM_AARCH64;
    header.e_version = 1;
    [self appendBytes:&header length:sizeof header];
}


-(void)writeFile
{
    
}

-(NSData*)data
{
    NSData *data = (NSData*)self.target;
    if ( data.length == 0 ) {
        [self writeFile];
    }
    return data;
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWELFReader.h"

@implementation MPWELFWriter(testing)

+(void)testCanWriteHeader
{
    MPWELFWriter *writer = [self stream];
    [writer writeHeader];
    
    NSData *elf=[writer data];
    [elf writeToFile:@"/tmp/emptyelf" atomically:YES];
    MPWELFReader *reader = [[[MPWELFReader alloc] initWithData:elf] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT([reader elfType],ET_REL,@"elf type");
    INTEXPECT( [reader elfType], ET_REL, @"elf type");
    INTEXPECT( [reader elfMachine], EM_AARCH64, @"machine type");
    INTEXPECT( [reader elfVersion], 1, @"version");
    INTEXPECT( [reader numProgramHeaders], 0 ,@"number of program headers");
//    INTEXPECT( [reader numSectionHeaders], 7 ,@"number of section headers");
//    INTEXPECT( [reader sectionHeaderEntrySize], 64 ,@"section header entry size");
//    INTEXPECT( [reader sectionHeaderOffset], 320 ,@"offset of section headers");
//    INTEXPECT([reader filetype],MH_OBJECT,@"filetype");

}

+(NSArray*)testSelectors
{
   return @[
			@"testCanWriteHeader",
			];
}

@end
