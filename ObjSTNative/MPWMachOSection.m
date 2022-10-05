//
//  MPWMachOSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import "MPWMachOSection.h"
#import <mach-o/loader.h>
#import <mach-o/reloc.h>
#import "MPWMachOReader.h"
#import "Mach_O_Structs.h"

@interface MPWMachOSection()

@property (nonatomic, strong) NSData *machoData;
@property (nonatomic, weak) MPWMachOReader *reader;

@end

@implementation MPWMachOSection
{
    const struct section_64 *sectionHeader;
}

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(MPWMachOReader*)newReader
{
    self=[super init];
    if ( self ) {
        sectionHeader=headerptr;
        self.machoData = newReader.data;
        self.reader = newReader;
    }
    return self;
}

-(NSString*)sectionName
{
    return @(sectionHeader->sectname);
}

-(NSString*)segmentName
{
    return @(sectionHeader->segname);
}

-(const void*)bytes
{
    return self.sectionData.bytes;
}

-(const void*)segmentBytes
{
    return [self.reader segmentBytes];
}


-(NSData*)sectionData
{
    return [self.machoData subdataWithRange:NSMakeRange(sectionHeader->offset,sectionHeader->size)];
}

-(NSArray<NSString*>*)objcClassNames
{
    NSString *base=[NSString stringWithCString:[self.reader bytes] + sectionHeader->offset length:sectionHeader->size-1];
    return [base componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithRange:NSMakeRange(0, 1)]];
}

-(int)numRelocEntries
{
    return sectionHeader->nreloc;
}

-(int)relocEntryOffset
{
    return sectionHeader->reloff;
}

-(struct relocation_info)relocEntryAt:(int)i
{
    const struct relocation_info *reloc=[self.machoData bytes] + [self relocEntryOffset];
    return reloc[i];
}

-(NSString*)nameOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return [self.reader symbolNameAt:reloc.r_symbolnum];
}

-(long)offsetOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_address;
}

-(int)typeOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_type;
}

-(bool)isExternalRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:0];
    return reloc.r_extern != 0;
}

static NSString* classSymbolForClass( NSString *className ) {
    return [@"_OBJC_CLASS_$_" stringByAppendingString:className];
}

static NSString* readOnlyPartOfClassSymbolForClass( NSString *className , BOOL metaclass) {
    return [(metaclass ?  @"__OBJC_METACLASS_RO_$_": @"__OBJC_CLASS_RO_$_")  stringByAppendingString:className];
}

static NSString* metaClassSymbolForClass( NSString *className ) {
    return [@"_OBJC_METACLASS_$_" stringByAppendingString:className];
}

-(int)classSymbolOffset:(NSString*)className
{
    return [self.reader indexOfSymbolNamed:classSymbolForClass(className)];
}

-(int)readOnlyClassSymbolOffset:(NSString*)className metaclass:(BOOL)metaclass
{
    return [self.reader indexOfSymbolNamed:readOnlyPartOfClassSymbolForClass(className,metaclass)];
}

-(long)readOnlyClassStructOffset:(NSString*)className metaclass:(BOOL)metaclass
{
    return [self.reader symbolOffsetAt:[self readOnlyClassSymbolOffset:className metaclass:metaclass]];
}

-(const Mach_O_Class_RO*)readOnlyClassStruct:(NSString*)className metaclass:(BOOL)metaclass
{
    int sectionIndex = [self.reader sectionForSymbolAt:[self readOnlyClassSymbolOffset:className metaclass:metaclass]];
    MPWMachOSection *readOnlyClassSection = [self.reader sectionAtIndex:sectionIndex];
    return [readOnlyClassSection segmentBytes] + [self readOnlyClassStructOffset:className metaclass:metaclass];
}


-(void)dealloc
{
    [_machoData release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"

@implementation MPWMachOSection(testing) 

+(MPWMachOReader*)readerForTestFile:(NSString*)name
{
    NSData *addmacho=[self frameworkResource:name category:@"macho"];
    MPWMachOReader *reader=[[[MPWMachOReader alloc] initWithData:addmacho] autorelease];
    return reader;
}

+(void)testSectionName
{
    MPWMachOReader *reader = [self readerForTestFile:@"class-with-method"];
    MPWMachOSection *textSection = [reader textSection];
    IDEXPECT([textSection sectionName],@"__text",@"text section section name");
    IDEXPECT([textSection segmentName],@"__TEXT",@"text section segment name");
    
    MPWMachOSection *objcConstantSection = [reader objcClassReadOnlySection];
    IDEXPECT([objcConstantSection sectionName],@"__objc_const",@"text section section name");
    IDEXPECT([objcConstantSection segmentName],@"__DATA",@"text section segment name");
    
}

+(void)testReadObjectiveCName
{
    MPWMachOReader *reader=[self readerForTestFile:@"class-with-method"];
    INTEXPECT( reader.numLoadCommands, 4 , @"load commands");
    INTEXPECT( reader.numSections, 9 , @"sections");
    MPWMachOSection *section=[reader objcClassNameSection];
    INTEXPECT( [section objcClassNames].count, 1, @"Objective-C classname");
    IDEXPECT( [section objcClassNames].firstObject, @"Hi", @"Objective-C classname");
}

+(void)testReadObjectiveCNames
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    INTEXPECT( reader.numLoadCommands, 4 , @"load commands");
    INTEXPECT( reader.numSections, 9 , @"sections");
    MPWMachOSection *section=[reader objcClassNameSection];
    INTEXPECT( [section objcClassNames].count, 2, @"Objective-C classname");
    NSString *firstClassName = [section objcClassNames].firstObject;
    NSString *secondClassName = [section objcClassNames].lastObject;
    IDEXPECT( firstClassName, @"FirstClass", @"Objective-C classname");
    IDEXPECT( secondClassName, @"SecondClass", @"Objective-C classname");
}

static int sizeOfClass( int numMethods ) {
    return sizeof(Mach_O_Class_RO) + numMethods * sizeof(MethodEntry) + (numMethods>0 ? sizeof(BaseMethods):0);
}

static int sizeOfClassAndMetaClass( int instanceMethods, int classMethods ) {
    return sizeOfClass(instanceMethods) + sizeOfClass(classMethods);
}

+(void)testSizeOfClassStructsInMacho
{
    INTEXPECT( sizeof(Mach_O_Class_RO), 72, @"size of read-only part of class (in Mach-O)");
    MPWMachOReader *oneClassOneMethodReader=[self readerForTestFile:@"class-with-method"];
    MPWMachOSection *readOnlyClassSectionOneClass = [oneClassOneMethodReader objcClassReadOnlySection];
    INTEXPECT( readOnlyClassSectionOneClass.sectionData.length , sizeOfClassAndMetaClass(1,0), @"size of RO class part");
    MPWMachOReader *twoClassReader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *readOnlyClassSectionTwoClasses = [twoClassReader objcClassReadOnlySection];
    INTEXPECT( readOnlyClassSectionTwoClasses.sectionData.length ,
              sizeOfClassAndMetaClass(3,0)+sizeOfClassAndMetaClass(1,0)  , @"size of RO class part for two clases, one with 3 instance methods, other with 1 instance method, not class methods");
}

+(void)testReadObjectiveC_ClassStructs
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *section=[reader objcClassNameSection];
    NSString *firstClassName = [section objcClassNames].firstObject;
//    NSString *secondClassName = [section objcClassNames].lastObject;

    int firstClassSymbolOffset = [section classSymbolOffset:firstClassName];
    int firstClassReadOnlySymbolOffset = [reader indexOfSymbolNamed:readOnlyPartOfClassSymbolForClass(@"FirstClass",NO)];
    int firstMetaClassSymbolOffset = [reader indexOfSymbolNamed:metaClassSymbolForClass(@"FirstClass")];
    INTEXPECT( firstClassSymbolOffset,28,@"symbol table entry of FirstClass");
    INTEXPECT( firstMetaClassSymbolOffset,30,@"symbol table entry of FirstClass's metaclass");
    INTEXPECT( firstClassReadOnlySymbolOffset,15,@"symbol table entry of FirstClass's RO class part");
    int sectionIndex = [reader sectionForSymbolAt:firstClassReadOnlySymbolOffset];
    INTEXPECT( sectionIndex,3,@"section that class RO part is in");
    MPWMachOSection *readOnlyClassSection = [reader sectionAtIndex:sectionIndex];
    IDEXPECT([readOnlyClassSection sectionName],@"__objc_data",@"text section section name");
    IDEXPECT([readOnlyClassSection segmentName],@"__DATA",@"text section segment name");
    
    
    
    long offsetOfFirstClassReadOnlyStruct = [section readOnlyClassStructOffset:firstClassName metaclass:NO];
    INTEXPECT( offsetOfFirstClassReadOnlyStruct,256, @"offset of FirstClass RO");
    INTEXPECT( [reader indexOfSymbolNamed:classSymbolForClass(@"SecondClass")],29,@"symbol table entry of SecondClass");
    INTEXPECT( [reader symbolOffsetAt:29],672, @"offset of SecondClass");
    
    const Mach_O_Class_RO *firstClassReadOnlyParts = [section readOnlyClassStruct:firstClassName metaclass:NO];
    INTEXPECT(firstClassReadOnlyParts->instanceSize ,8, @"size of FirstClass instances" );
    INTEXPECT(firstClassReadOnlyParts->instanceStart ,8, @"size of FirstClass instances" );
    
    const Mach_O_Class_RO *firstMetaClassReadOnlyParts = [section readOnlyClassStruct:firstClassName metaclass:YES];
    INTEXPECT(firstMetaClassReadOnlyParts->instanceSize ,40, @"size of FirstClass instances" );
    INTEXPECT(firstMetaClassReadOnlyParts->instanceStart ,40, @"size of FirstClass instances" );
}

+(void)testReadObjectiveC_MethodTable
{
    
}


+(NSArray*)testSelectors
{
   return @[
       @"testSectionName",
       @"testReadObjectiveCName",
       @"testReadObjectiveCNames",
       @"testSizeOfClassStructsInMacho",
       @"testReadObjectiveC_ClassStructs",
       @"testReadObjectiveC_MethodTable",
			];
}

@end
