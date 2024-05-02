//
//  MPWELFReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import "MPWELFReader.h"
#import "MPWELFSection.h"

#include "elf.h"

@interface MPWELFReader()

@property (nonatomic, strong) NSData *elfData;

@end

@implementation MPWELFReader

-initWithData:(NSData*)newData
{
    self=[super init];
    self.elfData=newData;
    return self;
}

-(const void*)bytes
{
    return [[self elfData] bytes];
}

-(Elf64_Ehdr*)header
{
    return (Elf64_Ehdr*)[self bytes];
}

-(NSString*)elfmagic
{
    return [[[NSString alloc] initWithBytes:[self bytes] length:4 encoding:NSASCIIStringEncoding] autorelease];
}

-(int)elfType
{
    return [self header]->e_type;
}

-(int)elfMachine
{
    return [self header]->e_machine;
}

-(int)elfVersion
{
    return [self header]->e_version;
}

-(int)numProgramHeaders
{
    return [self header]->e_phnum;
}

-(int)programHeaderEntrySize
{
    return [self header]->e_phentsize;
}

-(int)numSectionHeaders
{
    return [self header]->e_shnum;
}

-(int)sectionHeaderEntrySize
{
    return [self header]->e_shentsize;
}

-(long int)sectionHeaderOffset
{
    return [self header]->e_shoff;
}


-(BOOL)isHeaderValid
{
    return !strncmp([self bytes],ELFMAG ,4);
}

-(MPWELFSection*)sectionAtIndex:(int)numSection
{
    return ((numSection >= 0) && (numSection < [self numSectionHeaders])) ? [[[MPWELFSection alloc] initWithSectionHeaderPointer:[self bytes] + [self sectionHeaderOffset] + ([self sectionHeaderEntrySize] * numSection) ] autorelease] : nil;
}

@end


#import <MPWFoundation/MPWFoundation.h>

@implementation MPWELFReader(testing) 

+(instancetype)readerForTestFile:(NSString*)name
{
    NSData *addmacho=[self frameworkResource:name category:@"elf-o"];
    MPWELFReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    return reader;
}

+(void)testCanReadElfHeader
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    EXPECTNOTNIL(reader.elfData, @"elf data");
    EXPECTTRUE(!strncmp([reader bytes],ELFMAG ,4), @"elf magic");
    IDEXPECT( [reader elfmagic], @"\177ELF",@"elf magice");
    INTEXPECT( [reader elfType], ET_REL, @"elf type");
    INTEXPECT( [reader elfMachine], EM_AARCH64, @"machine type");
    INTEXPECT( [reader elfVersion], 1, @"version");
    INTEXPECT( [reader numProgramHeaders], 0 ,@"number of program headers");
    INTEXPECT( [reader numSectionHeaders], 7 ,@"number of section headers");
    INTEXPECT( [reader sectionHeaderEntrySize], 64 ,@"section header entry size");
    INTEXPECT( [reader sectionHeaderOffset], 320 ,@"offset of section headers");
}

+(void)testCanIdentifyHeader
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    EXPECTTRUE([reader isHeaderValid], @"got the right header");
    NSData *notelf = [@"Hello World!" asData];
    reader=[[[self alloc] initWithData:notelf] autorelease];
    EXPECTFALSE([reader isHeaderValid], @"not an ELF header");
}

+(void)testSectionHeaders
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    MPWELFSection *s0=[reader sectionAtIndex:0];
    INTEXPECT( [s0 sectionType], SHT_NULL, @"section 0 is a null section");
    MPWELFSection *stringTable=[reader sectionAtIndex:1];
    INTEXPECT( [stringTable sectionType], SHT_STRTAB, @"section 1 is a string table");
    INTEXPECT( [[reader sectionAtIndex:2] sectionType], SHT_PROGBITS, @"section 2 is progbits");
    INTEXPECT( [[reader sectionAtIndex:3] sectionType], SHT_PROGBITS, @"section 3 is progbits");
    INTEXPECT( [[reader sectionAtIndex:4] sectionType], SHT_PROGBITS, @"section 4 is progbits");
    INTEXPECT( [[reader sectionAtIndex:5] sectionType] , 1879002115, @"section 5 is unknown type 'llvm bits'");
    INTEXPECT( [[reader sectionAtIndex:6] sectionType] , SHT_SYMTAB, @"section 6 is symtab");
    EXPECTNIL( [reader sectionAtIndex:7], @"7 out of range");
}


+(NSArray*)testSelectors
{
   return @[
			@"testCanReadElfHeader",
            @"testCanIdentifyHeader",
            @"testSectionHeaders",
			];
}

@end
