//
//  MPWELFReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import "MPWELFReader.h"
#import "MPWELFSection.h"
#import <MPWFoundation/MPWFoundation.h>

#include "elf.h"

@interface MPWELFReader()

@property (nonatomic, strong) NSData *elfData;

@end

@implementation MPWELFReader
{
    MPWELFSection *stringTable;
}

lazyAccessor(MPWELFSection*, stringTable, setStringTable, findStringTable )

-(const char*)cStringAtOffset:(long)offset
{
    MPWELFSection *table=[self stringTable];
    return [[self elfData] bytes] + [table dataOffsetForOffset:offset];
}

-(NSString*)stringAtOffset:(long)offset
{
    return @([self cStringAtOffset:offset]);
}

-(MPWELFSection*)findStringTable
{
    MPWELFSection *theStringTable=nil;
    @autoreleasepool {
        for (int i=0,max=[self numSectionHeaders];i<max;i++) {
            MPWELFSection *possibleStringTable=[self sectionAtIndex:i];
            if ( [possibleStringTable sectionType]==SHT_STRTAB) {
                theStringTable = [possibleStringTable retain];
                break;
            }
        }
    }

    return [theStringTable autorelease];
}

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

-(const Elf64_Shdr*)sectionHeaderPointerAtIndex:(int)numSection
{
    return ((numSection >= 0) && (numSection < [self numSectionHeaders])) ? [self bytes] + [self sectionHeaderOffset] + ([self sectionHeaderEntrySize] * numSection) : NULL;
}

-(MPWELFSection*)sectionAtIndex:(int)numSection
{
    return ((numSection >= 0) && (numSection < [self numSectionHeaders])) ? [[[MPWELFSection alloc] initWithSectionHeaderPointer:[self sectionHeaderPointerAtIndex:numSection] ] autorelease] : nil;
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
    INTEXPECT( [s0 sectionNameOffset], 0, @"section 0 name offset");
    MPWELFSection *stringTable=[reader sectionAtIndex:1];
    INTEXPECT( [stringTable sectionType], SHT_STRTAB, @"section 1 is a string table");
    INTEXPECT( [stringTable sectionNameOffset], 66, @"section 1  name");
    INTEXPECT( [[reader sectionAtIndex:2] sectionType], SHT_PROGBITS, @"section 2 is progbits");
    INTEXPECT( [[reader sectionAtIndex:3] sectionType], SHT_PROGBITS, @"section 3 is progbits");
    INTEXPECT( [[reader sectionAtIndex:4] sectionType], SHT_PROGBITS, @"section 4 is progbits");
    INTEXPECT( [[reader sectionAtIndex:5] sectionType] , 1879002115, @"section 5 is unknown type 'llvm bits'");
    INTEXPECT( [[reader sectionAtIndex:6] sectionType] , SHT_SYMTAB, @"section 6 is symtab");
    EXPECTNIL( [reader sectionAtIndex:7], @"7 out of range");
}

+(void)testSectionHeaderNames
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:1] sectionNameOffset]], @".strtab",@"string table section name");
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:2] sectionNameOffset]], @".text",@"text section (2) name");
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:3] sectionNameOffset]], @".comment",@"comment section (3) name");
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:4] sectionNameOffset]], @".note.GNU-stack",@"stack section (4) name");
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:5] sectionNameOffset]], @".llvm_addrsig",@"llvm section (5) name");
    IDEXPECT( [reader stringAtOffset:[[reader sectionAtIndex:6] sectionNameOffset]], @".symtab",@"symtab section (6) name");
}


+(void)testFindStringTable
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    MPWELFSection *stringTable=[reader findStringTable];
    INTEXPECT( [stringTable sectionType], SHT_STRTAB, @"found string table");
}


+(NSArray*)testSelectors
{
   return @[
			@"testCanReadElfHeader",
            @"testCanIdentifyHeader",
            @"testSectionHeaders",
            @"testFindStringTable",
            @"testSectionHeaderNames",
			];
}

@end
