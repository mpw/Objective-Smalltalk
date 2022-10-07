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
    char name[32]={};
    memcpy( name,sectionHeader->sectname,sizeof sectionHeader->sectname);
    return @(name);
}

-(NSString*)segmentName
{
    char name[32]={};
    memcpy( name,sectionHeader->segname,sizeof sectionHeader->segname);
    return @(name);
}

-(const void*)bytes
{
    return self.sectionData.bytes;
}

-(const void*)segmentBytes
{
    return [self.reader segmentBytes];
}

-(long)offset
{
    return sectionHeader->offset;
}

-(NSData*)sectionData
{
    return [self.machoData subdataWithRange:NSMakeRange(sectionHeader->offset,sectionHeader->size)];
}

-(NSArray<NSString*>*)strings
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

-(int)symbolNumberOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:i];
    return reloc.r_symbolnum;
}

-(NSString*)nameOfRelocEntryAt:(int)i
{
    return [self.reader symbolNameAt:[self symbolNumberOfRelocEntryAt:i]];
}

-(long)offsetOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:i];
    return reloc.r_address;
}

-(int)typeOfRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:i];
    return reloc.r_type;
}

-(bool)isExternalRelocEntryAt:(int)i
{
    struct relocation_info reloc=[self relocEntryAt:i];
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

-(int)indexOfRelocationEntryAtOffset:(long)offset
{
    int entry=-1;
    for (int i=0;i<[self numRelocEntries];i++) {
        if ([self offsetOfRelocEntryAt:i]==offset) {
            entry=i;
            break;
        }
    }
    return entry;
}

-(int)indexOfSymboltableEntryAtOffset:(long)offset
{
    int entry=-1;
    int relocEntryOffset = [self indexOfRelocationEntryAtOffset:offset];
    if ( relocEntryOffset >= 0 ) {
        entry = [self symbolNumberOfRelocEntryAt:relocEntryOffset];
    }
    return entry;
}

-(MPWMachOSection*)sectionForRelocEntryAt:(int)which
{
    int symbolIndex = [self symbolNumberOfRelocEntryAt:which];
    int sectionIndex = [self.reader sectionForSymbolAt:symbolIndex];
    return [self.reader sectionAtIndex:sectionIndex];
//    INTEXPECT( sectionIndex,4, @"should point to objc data");
    //    MPWMachOSection *targetSection1=[section.reader sectionAtIndex:sectionIndex];
}

-(long)shiftedOffsetForBaseSymbolOffset:(long)baseOffset
{
    return baseOffset - ([self offset] - [self.reader segmentOffset]);
}

-(long)offsetInTargetSectionForRelocEntryAt:(int)which
{
    MPWMachOSection *targetSection = [self sectionForRelocEntryAt:which];
    int symbolEntryIndex = [self symbolNumberOfRelocEntryAt:which];
    return [targetSection shiftedOffsetForBaseSymbolOffset:[self.reader symbolOffsetAt:symbolEntryIndex]];
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
    INTEXPECT( [section strings].count, 1, @"Objective-C classname");
    IDEXPECT( [section strings].firstObject, @"Hi", @"Objective-C classname");
}

+(void)testReadObjectiveCNames
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    INTEXPECT( reader.numLoadCommands, 4 , @"load commands");
    INTEXPECT( reader.numSections, 9 , @"sections");
    MPWMachOSection *section=[reader objcClassNameSection];
    INTEXPECT( [section strings].count, 2, @"Objective-C classname");
    NSString *firstClassName = [section strings].firstObject;
    NSString *secondClassName = [section strings].lastObject;
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
    NSString *firstClassName = [section strings].firstObject;
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
    IDEXPECT([readOnlyClassSection sectionName],@"__objc_const",@"section of ObjC read only parts of class");
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

+(void)testRelocationEntriesInObjectiveCDataSection
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *objcDataSection=[reader objcDataSection];
    for (int i=0;i<[objcDataSection numRelocEntries];i++) {
        NSLog(@"reloc entry[%d] offset = %ld name = %@",i,[objcDataSection offsetOfRelocEntryAt:i],[objcDataSection nameOfRelocEntryAt:i]);
        //        if ([objcDataSection offsetOfRelocEntryAt:i]==offsetOfConstantPartWithinClass) {
        //            NSLog(@"=== found reloc entry at %d",i);
    }
}


static int offsetOfReadOnlyPointerFromBaseClass() {
    Mach_O_Class c;
    return (void*)&c.data - (void*)&c;
}

static int offsetOfMethodListPointerFromBaseClassRO() {
    Mach_O_Class_RO c;
    return (void*)&c.methods - (void*)&c;
}

+(void)testReadObjectiveClassDefinitionsViaClassList
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *section=[reader objcClassListSection];
    IDEXPECT( [section sectionName],@"__objc_classlist",@"it is the class list");
    IDEXPECT( [section segmentName],@"__DATA",@"segment of class list");
    INTEXPECT( [section numRelocEntries],2,@"two classes");
    INTEXPECT( [section sectionData].length, 16, @"two pointers worth of data");
    IDEXPECT( [section nameOfRelocEntryAt:0],@"_OBJC_CLASS_$_SecondClass",@"first pointer points to");
    IDEXPECT( [section nameOfRelocEntryAt:1],@"_OBJC_CLASS_$_FirstClass",@"second pointer points to");
    
    MPWMachOSection *targetSection1=[section sectionForRelocEntryAt:0];
    long offsetOfSecondClass = [section offsetInTargetSectionForRelocEntryAt:0];
    long offsetOfSecondConstantPartWithinClass = offsetOfSecondClass + offsetOfReadOnlyPointerFromBaseClass();
    INTEXPECT( offsetOfSecondClass, 0x78 , @"offset of class");
    
    int entry = [targetSection1 indexOfSymboltableEntryAtOffset:offsetOfSecondConstantPartWithinClass];
    INTEXPECT(entry,23,@"symtab entry");
    IDEXPECT([reader symbolNameAt:entry], @"__OBJC_CLASS_RO_$_SecondClass",@"ref to RO paart");
    IDEXPECT( [targetSection1 sectionName], @"__objc_data" , @"objc data?? ");
    
    
    long offsetConstantPartWithinFirstClass = [section offsetInTargetSectionForRelocEntryAt:1] + offsetOfReadOnlyPointerFromBaseClass();
    INTEXPECT( offsetConstantPartWithinFirstClass, 0x48 , @"offset of class");
    int entry2 = [targetSection1 indexOfSymboltableEntryAtOffset:offsetConstantPartWithinFirstClass];
    IDEXPECT([reader symbolNameAt:entry2], @"__OBJC_CLASS_RO_$_FirstClass",@"ref to RO paart");


}

+(void)testReadObjectiveC_MethodNameList
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *section=[reader objcMethodNamesSection];
    NSArray<NSString*>* methodNames=[section strings];
    INTEXPECT( methodNames.count, 4, @"Objective-C method names");
    IDEXPECT(methodNames[0],@"components:splitInto:",@"first method" );
    IDEXPECT(methodNames[1],@"hi",@"second method" );
    IDEXPECT(methodNames[2],@"there",@"third method" );
    IDEXPECT(methodNames[3],@"more",@"fourth method" );
}

+(void)testReadObjectiveC_MethodListForClass
{
    MPWMachOReader *reader=[self readerForTestFile:@"two-classes"];
    MPWMachOSection *section=[reader objcClassListSection];
    MPWMachOSection *objcDataSection=[section sectionForRelocEntryAt:0];
    long offsetOfSecondConstantPartWithinClass = [section offsetInTargetSectionForRelocEntryAt:0] + offsetOfReadOnlyPointerFromBaseClass();
    
    int entry = [objcDataSection indexOfSymboltableEntryAtOffset:offsetOfSecondConstantPartWithinClass];
    INTEXPECT(entry,23,@"symtab entry");
  
    MPWMachOSection *objcConstSection=[reader sectionAtIndex:[reader sectionForSymbolAt:entry]];
    IDEXPECT( [objcConstSection sectionName], @"__objc_const" , @"objc const");
    long roClassOffset=[reader symbolOffsetAt:entry];
    INTEXPECT(roClassOffset, 0x1e0 , @"offset of RO-part of SecondClass");
    long actualOffset = [objcConstSection shiftedOffsetForBaseSymbolOffset:roClassOffset];
    const Mach_O_Class_RO *ro_class = [objcConstSection bytes] + actualOffset;
    INTEXPECT( ro_class->instanceSize, 8, @"size");
    long methodTablePointerOffset = actualOffset + offsetOfMethodListPointerFromBaseClassRO();
    int relocEntryForMethodTable = [objcConstSection indexOfRelocationEntryAtOffset:methodTablePointerOffset];
    INTEXPECT(relocEntryForMethodTable, 0, @"relocEntry for method table");
    IDEXPECT([objcConstSection nameOfRelocEntryAt:0],@"__OBJC_$_INSTANCE_METHODS_SecondClass",@"method table name");
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testSectionName",
       @"testReadObjectiveCName",
       @"testReadObjectiveCNames",
       @"testSizeOfClassStructsInMacho",
       @"testReadObjectiveC_ClassStructs",
       @"testReadObjectiveClassDefinitionsViaClassList",
       @"testReadObjectiveC_MethodNameList",
       @"testReadObjectiveC_MethodListForClass",
			];
}

@end
