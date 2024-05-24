//
//  MPWELFWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 05.05.24.
//

#import "MPWELFWriter.h"
#import "elf.h"
#import "MPWStringTableWriter.h"
#import "MPWELFSectionWriter.h"
#import "MPWELFSection.h"
#import "MPWELFSymbolTable.h"

@interface MPWELFWriter()

@property (nonatomic, strong) MPWStringTableWriter *sectionNameStringTableWriter;
@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, assign) int sectionStringTableSection;
@property (nonatomic, strong) MPWELFSectionWriter *textSection;
@property (nonatomic, strong) MPWELFSectionWriter *symbolTable;
@property (nonatomic, strong) MPWELFSectionWriter *stringTable;

@end

@implementation MPWELFWriter
{
    Elf64_Sym *symtab;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.sectionNameStringTableWriter=[MPWStringTableWriter writer];
    self.sections=[NSMutableArray array];
    symtabCapacity = 10;
    [self growSymtab];
    [self addNullSection];
    [self addSectionHeaderStringTable];
    [self addStringTable];
    [self addSymbolTable];
    return self;
}

-(void)addSection:(MPWELFSectionWriter*)section name:(NSString*)name
{
    section.sectionNumber = (int)self.sections.count;
    if (name) {
        section.nameIndex = [self.sectionNameStringTableWriter stringTableOffsetOfString:name];
    }
    [self.sections addObject:section];
}

-(void)growSymtab
{
    symtabCapacity *= 2;
    Elf64_Sym *newSymtab = calloc( symtabCapacity , sizeof *symtab);
    if ( symtab ) {
        memcpy( newSymtab, symtab, symtabCount * sizeof *symtab);
        free(symtab);
    }
    symtab = newSymtab;
}

-(void)writeSymtabEntryOfType:(int)theType section:(int)theSection stringOffset:(int)stringOffset address:(long)addreess
{
    Elf64_Sym entry={0};
    entry.st_info = theType;                //  need a little more detail here?
    entry.st_shndx = theSection;
    entry.st_name = stringOffset;
    //        NSLog(@"for symbol %@ offset is %d",symbol,offset);
    entry.st_value = addreess;
    symtab[symtabCount++]=entry;
}



-(long)sectionHeaderOffset
{
    return sizeof(Elf64_Ehdr);
}

-(long)sectionOffset
{
    return [self sectionHeaderOffset] + self.sections.count * sizeof(Elf64_Shdr);
}

-(void)writeHeader
{
    unsigned char ident[EI_NIDENT]={ 0x7f, 'E', 'L' , 'F', ELFCLASS64,ELFDATA2LSB,1,0,0,0,0,0,0,0,0,0};
    Elf64_Ehdr header={};
    memcpy(&(header.e_ident), ident, 16);
    header.e_type = ET_REL;
    header.e_machine = EM_AARCH64;
    header.e_version = 1;
    header.e_shstrndx = self.sectionStringTableSection;
    header.e_ehsize = sizeof header;
    header.e_shentsize = sizeof(Elf64_Shdr);
    header.e_shnum = (int)self.sections.count;
    header.e_shoff = [self sectionHeaderOffset];  // would need to add the size of the progam header entries
    [self appendBytes:&header length:sizeof header];
}

-(void)addNullSection
{
    [self addSection:[MPWELFSectionWriter stream] name:nil];
}

-(void)addSectionHeaderStringTable
{
    MPWELFSectionWriter *stringTable=[MPWELFSectionWriter stream];
    stringTable.sectionType = SHT_STRTAB;
    stringTable.sectionData = self.sectionNameStringTableWriter.data;
    [self addSection:stringTable name:@".shstrtab"];
    self.sectionStringTableSection = stringTable.sectionNumber;
}

-(void)addStringTable
{
    self.stringTable=[MPWELFSectionWriter stream];
    self.stringTable.sectionType = SHT_STRTAB;
    self.stringTable.sectionData = self.stringTableWriter.data;
    [self addSection:self.stringTable name:@".strtab"];
}

-(void)addSymbolTable
{
    self.symbolTable=[MPWELFSectionWriter stream];
    self.symbolTable.sectionType = SHT_SYMTAB;
    self.symbolTable.entrySize = sizeof *symtab;
    self.symbolTable.sectionLink = self.stringTable.sectionNumber;
    [self addSection:self.symbolTable name:@".symtab"];
}

-(void)addTextSection:(NSData*)textSectionData
{
    self.textSection=[MPWELFSectionWriter stream];
    self.textSection.sectionType = SHT_PROGBITS;
    self.textSection.sectionData = textSectionData;
    [self addSection:self.textSection name:@".text"];
}

-(void)computeSectionOffsets
{
    long sectionOffset=[self sectionOffset];
    for (MPWELFSectionWriter *section in self.sections) {
        section.sectionOffset = sectionOffset;
        sectionOffset += section.sectionLength;
    }
}

-(void)writeSectionHeaders
{
    for (MPWELFSectionWriter *section in self.sections) {
        [section writeSctionHeaderOnWriter:self];
    }
}
-(void)writeSectionData
{
    for (MPWELFSectionWriter *section in self.sections) {
        [section writeSectionDataOnWriter:self];
    }
}

-(void)finalizeSectionData
{
    self.symbolTable.sectionData=[NSData dataWithBytes:symtab length:symtabCount * sizeof *symtab];
}

-(void)writeFile
{
    [self finalizeSectionData];
    [self computeSectionOffsets];
    [self writeHeader];
    [self writeSectionHeaders];
    [self writeSectionData];
}

-(NSData*)data
{
    NSData *data = (NSData*)self.target;
    if ( data.length == 0 ) {
        [self writeFile];
    }
    return data;
}

-(int)globalFuncSymbolType
{
    return ELF64_ST_INFO(STB_GLOBAL, STT_FUNC );
}

-(int)textSectionNumber
{
    return self.textSection.sectionNumber;
}

-(void)dealloc
{
    [_sectionNameStringTableWriter release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWELFReader.h"

@implementation MPWELFWriter(testing)

+(void)testCanWriteHeader
{
    MPWELFWriter *writer = [self stream];
    [writer writeFile];
    
    NSData *elf=[writer data];
    //    [elf writeToFile:@"/tmp/emptyelf" atomically:YES];
    MPWELFReader *reader = [[[MPWELFReader alloc] initWithData:elf] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT( [reader elfType], ET_REL, @"elf type");
    INTEXPECT( [reader elfMachine], EM_AARCH64, @"machine type");
    INTEXPECT( [reader elfVersion], 1, @"version");
    INTEXPECT( [reader elfClass], ELFCLASS64, @"class (64 bit)");
    INTEXPECT( [reader elfEndianness], ELFDATA2LSB, @"little endian");
    INTEXPECT( [reader numProgramHeaders], 0 ,@"number of program headers");
    //    INTEXPECT( [reader numSectionHeaders], 7 ,@"number of section headers");
    //    INTEXPECT( [reader sectionHeaderEntrySize], 64 ,@"section header entry size");
    //    INTEXPECT( [reader sectionHeaderOffset], 320 ,@"offset of section headers");
    //    INTEXPECT([reader filetype],MH_OBJECT,@"filetype");
    
}



+(void)testCanWriteNullSection
{
    MPWELFWriter *writer = [self stream];

    [writer writeFile];

    
    NSData *elf=[writer data];
    INTEXPECT(elf.length,360,@"size of ELF");
    
    
   [elf writeToFile:@"/tmp/elfwithnull" atomically:YES];
    MPWELFReader *reader = [[[MPWELFReader alloc] initWithData:elf] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    INTEXPECT( [reader numProgramHeaders], 0 ,@"number of program headers");
    
    MPWELFSection *nullSection=[reader findElfSectionOfType:SHT_NULL name:nil];
    EXPECTNOTNIL(nullSection, @"got a NULL section");
    INTEXPECT( [reader numSectionHeaders], 4 ,@"number of section headers");
    INTEXPECT( [reader sectionHeaderEntrySize], 64 ,@"section header entry size");
    INTEXPECT( [reader sectionHeaderOffset], 64 ,@"offset of section headers");
}


+(void)testCanWriteTextSectionWithName
{
    MPWELFWriter *writer = [self stream];
    NSData *add_function_payload=[self resourceWithName:@"add" type:@"aarch64"];
    EXPECTNOTNIL(add_function_payload, @"got the payload");
    
    [writer addTextSection:add_function_payload];
    [writer writeFile];

    
    NSData *elf=[writer data];
    INTEXPECT(elf.length,440,@"size of ELF");

    MPWELFReader *reader = [[[MPWELFReader alloc] initWithData:elf] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    MPWELFSection *text=[reader findElfSectionOfType:SHT_PROGBITS name:nil];
    EXPECTNOTNIL(text, @"got a text section");
    NSData *textSectionData = [text data];
    INTEXPECT(textSectionData.length,8,@"size of function body is two instructions" );
    IDEXPECT(textSectionData,add_function_payload,@"got the same text section data out");
    IDEXPECT([text sectionName],@".text",@"text section name");
    IDEXPECT([[reader sectionStringTable] sectionName],@".shstrtab",@"section header string table name");
}

+(void)testWriteLinkableAddFunction
{
    MPWELFWriter *writer = [self stream];
//    NSLog(@"bundle for class: %@",[NSBundle bundleForClass:self]);
//    NSLog(@"path for class bundle: %@",[[NSBundle bundleForClass:self] bundlePath]);
//    NSLog(@"resource path for class bundle: %@",[[NSBundle bundleForClass:self] resourcePath]);
    NSData *add_function_payload=[self resourceWithName:@"add" type:@"aarch64"];
    
    [writer addTextSection:add_function_payload];
    [writer declareGlobalSymbol:@"add" atOffset:0];

    
    NSData *elf=[writer data];
    
    
    
    [elf writeToFile:@"/tmp/add-generated.elfo" atomically:YES];
    MPWELFReader *reader = [[[MPWELFReader alloc] initWithData:elf] autorelease];
    EXPECTTRUE([reader isHeaderValid], @"header valid");
    
    MPWELFSymbolTable *symbolTable=[reader symbolTable];
    EXPECTNOTNIL([reader sectionStringTable],@"need a section string table");
    EXPECTNOTNIL([reader stringTable],@"need a string string table");
    INTEXPECT( [symbolTable sectionType], SHT_SYMTAB, @"found symbol table");
    EXPECTTRUE([symbolTable isKindOfClass:[MPWELFSymbolTable class]], @"and it's an actual symbol table");
//    [symbolTable.data writeToFile:@"/tmp/symtab-read.elfosection" atomically:YES];

    INTEXPECT( [symbolTable numEntries], 1, @"number of entries");
    INTEXPECT( [symbolTable entrySize], sizeof(Elf64_Sym),@"64 bit symbol table");
    
    
    IDEXPECT( [symbolTable symbolNameAt:0], @"add", @"name of symbol table entry 2");

    
}
+(NSArray*)testSelectors
{
   return @[
			@"testCanWriteHeader",
            @"testCanWriteNullSection",
            @"testCanWriteTextSectionWithName",
            @"testWriteLinkableAddFunction",
			];
}

@end
