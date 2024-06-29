//
//  MPWELFReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import "MPWELFReader.h"
#import "MPWELFSection.h"
#import "MPWELFSymbolTable.h"
#import "MPWELFRelocationTable.h"

#import <MPWFoundation/MPWFoundation.h>

#include "elf.h"

@interface MPWELFReader()

@property (nonatomic, strong) NSData *elfData;

@end

@implementation MPWELFReader
{
    MPWELFSection *stringTable;
    MPWELFSection *sectionStringTable;
    MPWELFSymbolTable *symbolTable;
}

lazyAccessor(MPWELFSection*, stringTable, setStringTable, findStringTable )
lazyAccessor(MPWELFSection*, sectionStringTable, setSectionStringTable, findSectionStringTable )
lazyAccessor(MPWELFSymbolTable*, symbolTable, setSymbolTable, findSymbolTable )

-(const char*)cSectionNameAtOffset:(long)offset
{
    MPWELFSection *table=[self sectionStringTable];
    return [[self elfData] bytes] + [table dataOffsetForOffset:offset];
}

-(NSString*)sectionNameAtOffset:(long)offset
{
    return @([self cSectionNameAtOffset:offset]);
}

-(const char*)cStringAtOffset:(long)offset
{
    MPWELFSection *table=[self stringTable];
    NSAssert(table != nil, @"string table not foud");
    return [[self elfData] bytes] + [table dataOffsetForOffset:offset];
}

-(NSString*)stringAtOffset:(long)offset
{
    return @([self cStringAtOffset:offset]);
}


-(MPWELFSection*)findElfSectionOfType:(int)type name:(nullable NSString*)name
{
    MPWELFSection *theStringTable=nil;
    @autoreleasepool {
        for (int i=0,max=[self numSectionHeaders];i<max;i++) {
            MPWELFSection *possibleStringTable=[self sectionAtIndex:i];
            if ( [possibleStringTable sectionType]==type ) {
                if ( !name || [name isEqual:[possibleStringTable sectionName]]) {
                    theStringTable = [possibleStringTable retain];
                    break;
                }
            }
        }
    }
    
    return [theStringTable autorelease];
}

-(MPWELFSection*)findElfSectionOfType:(int)type
{
    return [self findElfSectionOfType:type name:nil];
}

-(MPWELFSection*)findStringTable
{
    return [self findElfSectionOfType:SHT_STRTAB name:@".strtab"];
}

-(int)sectionStringTableSectionNumber
{
    return [self header]->e_shstrndx;
}

-(MPWELFSection*)findSectionStringTable
{
    return [self sectionAtIndex:self.sectionStringTableSectionNumber];
}

-(MPWELFSymbolTable*)findSymbolTable
{
    MPWELFSection *symbolSection = [self findElfSectionOfType:SHT_SYMTAB];
    return [[[MPWELFSymbolTable alloc] initWithSectionNumber:symbolSection.sectionNumber reader:self] autorelease];
}

-(MPWELFRelocationTable*)findTextRelectionTable
{
    MPWELFSection *symbolSection = [self findElfSectionOfType:SHT_RELA name:@".rela.text"];
    return [[[MPWELFRelocationTable alloc] initWithSectionNumber:symbolSection.sectionNumber reader:self] autorelease];
}



-(instancetype)initWithData:(NSData*)newData
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

-(int)elfClass
{
    return [self header]->e_ident[4];
}

-(int)elfEndianness
{
    return [self header]->e_ident[5];
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

-(long)sectionHeaderOffset
{
    return [self header]->e_shoff;
}


-(BOOL)isHeaderValid
{
    return [self.elfData length] >= sizeof(Elf64_Ehdr) 
        && !strncmp([self bytes],ELFMAG ,4) &&
    [self header]->e_ehsize == sizeof(Elf64_Ehdr);
}

-(const void*)sectionHeaderPointerAtIndex:(int)numSection
{
    return ((numSection >= 0) && (numSection < [self numSectionHeaders])) ? [self bytes] + [self sectionHeaderOffset] + ([self sectionHeaderEntrySize] * numSection) : NULL;
}

-(MPWELFSection*)sectionAtIndex:(int)numSection
{
    return ((numSection >= 0) && (numSection < [self numSectionHeaders])) ? [[[MPWELFSection alloc] initWithSectionNumber:numSection reader:self] autorelease] : nil;
}

-(NSString*)symbolNameAt:(int)anIndex
{
    return [self.symbolTable symbolNameAt:anIndex];
}

-(BOOL)isSymbolUndefinedAt:(int)anIndex
{
    return [self.symbolTable symbolSectionAtIndex:anIndex] == 0;
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

+(instancetype)readerForAdd
{
    return [self readerForTestFile:@"add"];
}

+(instancetype)readerForExternalFunction
{
    return [self readerForTestFile:@"call-external-fn"];
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
    INTEXPECT( [reader elfClass], ELFCLASS64, @"class (64 bit)");
    INTEXPECT( [reader elfEndianness], ELFDATA2LSB, @"little endian");
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

+(void)testSectionHeaderNamesOfEmpty
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    IDEXPECT( [[reader sectionAtIndex:1] sectionName], @".strtab",@"string table section name");
    IDEXPECT( [[reader sectionAtIndex:2] sectionName], @".text",@"text section (2) name");
    IDEXPECT( [[reader sectionAtIndex:3] sectionName], @".comment",@"comment section (3) name");
    IDEXPECT( [[reader sectionAtIndex:4] sectionName], @".note.GNU-stack",@"stack section (4) name");
    IDEXPECT( [[reader sectionAtIndex:5] sectionName], @".llvm_addrsig",@"llvm section (5) name");
    IDEXPECT( [[reader sectionAtIndex:6] sectionName], @".symtab",@"symtab section (6) name");
}

+(void)testSectionHeaderNamesOfAdd
{
    MPWELFReader *reader=[self readerForAdd];
    IDEXPECT( [[reader sectionAtIndex:1] sectionName], @".text",@"text section (1) name");
    IDEXPECT( [[reader sectionAtIndex:2] sectionName], @".data",@"data section (2) name");
    IDEXPECT( [[reader sectionAtIndex:3] sectionName], @".bss",@"bss section (3) name");
    IDEXPECT( [[reader sectionAtIndex:4] sectionName], @".comment",@".commen section (4) name");
    IDEXPECT( [[reader sectionAtIndex:5] sectionName], @".note.GNU-stack",@".note.GNU-stack section (5) name");
    IDEXPECT( [[reader sectionAtIndex:6] sectionName], @".eh_frame",@"eh_frame section (6) name");
    IDEXPECT( [[reader sectionAtIndex:7] sectionName], @".rela.eh_frame",@"rela.eh_frame section (7) name");
    IDEXPECT( [[reader sectionAtIndex:8] sectionName], @".symtab",@"symtab section (8) name");
    IDEXPECT( [[reader sectionAtIndex:9] sectionName], @".strtab",@"strtab section (9) name");
    IDEXPECT( [[reader sectionAtIndex:10] sectionName], @".shstrtab",@"eh_frame section (10) name");
}


+(void)testFindStringTable
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    MPWELFSection *stringTable=[reader findStringTable];
    INTEXPECT( [stringTable sectionType], SHT_STRTAB, @"found string table");
}

+(void)testFindSymbolTable
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function-clang"];
    MPWELFSection *symbolTable=[reader findSymbolTable];
    INTEXPECT( [symbolTable sectionType], SHT_SYMTAB, @"found symbol table");
}

+(void)testFindSymbols
{
    MPWELFReader *reader=[self readerForAdd];
    MPWELFSymbolTable *symbolTable=[reader symbolTable];
    INTEXPECT( [symbolTable sectionType], SHT_SYMTAB, @"found symbol table");
    EXPECTTRUE([symbolTable isKindOfClass:[MPWELFSymbolTable class]], @"and it's an actual symbol table");
    INTEXPECT( [symbolTable numEntries], 11, @"number of entries");
    INTEXPECT( [symbolTable entrySize], sizeof(Elf64_Sym),@"64 bit symbol table");
    [symbolTable.data writeToFile:@"/tmp/addelf.symtab" atomically:YES];
    
    IDEXPECT( [symbolTable symbolNameAt:1], @"add.c", @"name of symbol table entry 1");
    IDEXPECT( [symbolTable symbolNameAt:5], @"$x", @"name of symbol table entry 5");
    IDEXPECT( [symbolTable symbolNameAt:7], @"$d", @"name of symbol table entry 7");
    IDEXPECT( [symbolTable symbolNameAt:10], @"add", @"name of symbol table entry 10");
    
    INTEXPECT( [symbolTable symbolTypeAtIndex:10], STT_FUNC, @"add should be function");
    INTEXPECT( [symbolTable symbolValueAtIndex:10], 0, @"add offset should be zero");
    INTEXPECT( [symbolTable symbolValueAtIndex:7], 20, @"$d offset should be 20");
}

+(void)testExtractTextSection
{
    MPWELFReader *reader=[self readerForAdd];
    MPWELFSection *text=[reader findElfSectionOfType:SHT_PROGBITS name:@".text"];
    EXPECTNOTNIL(text, @"got a text section");
    INTEXPECT([text sectionNumber],1,@"section number of text segment");
    IDEXPECT([text sectionName],@".text",@"text section");
    INTEXPECT([text sectionSize],8,@"text section size");
    NSData *textData = [text data];
    INTEXPECT(textData.length,8,@"text section size");
}

+(void)testFindRelocationTable
{
    MPWELFReader *reader=[self readerForExternalFunction];
    INTEXPECT([reader numSectionHeaders],12, @"number of sections");
    MPWELFRelocationTable *relocations=[reader findTextRelectionTable];
    EXPECTNOTNIL(relocations, @"got relocations");
    INTEXPECT( relocations.numEntries, 1, @"number of relocations");
    INTEXPECT( relocations.sectionType, 4, @"section type");
    INTEXPECT( relocations.sectionLink, 9, @"section link");
    INTEXPECT( relocations.entrySize, sizeof(Elf64_Rela), @"size of relocation");
}


+(void)testReadELFWithExternalSymbols
{
    MPWELFReader *reader=[self readerForExternalFunction];
    INTEXPECT([reader numSectionHeaders],12, @"number of sections");
        for (int i=0;i<12;i++) {
            NSLog(@"section[%d]=%@",i,[reader sectionAtIndex:i]);
        }
    IDEXPECT( [reader symbolNameAt:10],@"fn",@"defined function");
    IDEXPECT( [reader symbolNameAt:11],@"other",@"external function");
    EXPECTFALSE( [reader isSymbolUndefinedAt:10],@"fn should not be undefined");
    EXPECTTRUE( [reader isSymbolUndefinedAt:11],@"other should  be undefined");
  
//    Relocation entries 
//    gnustep@06578dc4dea1[TestResources]readelf -r call-external-fn.elf-o
//    
//    Relocation section '.rela.text' at offset 0x208 contains 1 entry:
//    Offset          Info           Type           Sym. Value    Sym. Name + Addend
//    000000000010  000b0000011b R_AARCH64_CALL26  0000000000000000 other + 0
//    
//    Relocation section '.rela.eh_frame' at offset 0x220 contains 1 entry:
//    Offset          Info           Type           Sym. Value    Sym. Name + Addend
//    00000000001c  000200000105 R_AARCH64_PREL32  0000000000000000 .text + 0

    
    
//    IDEXPECT( [reader symbolNameAt:3],@"_other",@"referenced function");
//    EXPECTTRUE( [reader isSymbolUndefinedAt:3],@"_other should be undefined");
//    INTEXPECT([reader symbolOffsetAt:3],0,@"offset of undefined symbols is 0");
//    INTEXPECT([[reader textSection] numRelocEntries],1,@"number of undefined symbol reloc entries");
//    INTEXPECT([[reader textSection] relocEntryOffset],0x1c0,@"offset of undefined symbol reloc entries");
////    INTEXPECT([[reader textSection] typeOfRelocEntryAt:0],ARM64_RELOC_BRANCH26,@"reloc entry type");
//    IDEXPECT([[reader textSection] nameOfRelocEntryAt:0],@"_other",@"external symbol");
//    INTEXPECT([[reader textSection] offsetOfRelocEntryAt:0],8,@"address");
//    EXPECTTRUE([[reader textSection] isExternalRelocEntryAt:0],@"external");
}


+(NSArray*)testSelectors
{
   return @[
			@"testCanReadElfHeader",
            @"testCanIdentifyHeader",
            @"testSectionHeaders",
            @"testSectionHeaderNamesOfEmpty",
            @"testSectionHeaderNamesOfAdd",
            @"testFindStringTable",
            @"testFindSymbolTable",
            @"testFindSymbols",
            @"testExtractTextSection",
            @"testFindRelocationTable",
            @"testReadELFWithExternalSymbols",
			];
}

@end
