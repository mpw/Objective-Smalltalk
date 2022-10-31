//
//  MPWMachOClassWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 21.10.22.
//

#import "MPWMachOClassWriter.h"
#import "MPWMachOWriter.h"
#import "MPWMachOSectionWriter.h"
#import "Mach_O_Structs.h"
#import <mach-o/loader.h>

@interface MPWMachOClassWriter()

@property (nonatomic,strong) MPWMachOWriter* writer;

@end

@implementation MPWMachOClassWriter

CONVENIENCEANDINIT(writer, WithWriter:(MPWMachOWriter*)writer)
{
    self=[super init];
    self.writer = writer;
    self.instanceSize = 8;      //  minimum due to ISA pointer
    return self;
}


-(NSString*)classNameSymbolName
{
    return [NSString stringWithFormat:@"_%@_name",self.nameOfClass];
}

-(NSString*)roClassPartSymbol
{
    return [NSString stringWithFormat:@"__OBJC_CLASS_RO_%@",self.nameOfClass];
}

-(NSString*)roMetaClassPartSymbol
{
    return [NSString stringWithFormat:@"__OBJC_METACLASS_RO_%@",self.nameOfClass];
}

-(NSString*)classPartSymbol
{
    return [NSString stringWithFormat:@"_OBJC_CLASS_$_%@",self.nameOfClass];
}

-(NSString*)superclassSymbolName
{
    return [NSString stringWithFormat:@"_OBJC_CLASS_$_%@",self.nameOfSuperClass];
}

-(NSString*)metaclassSymbolName
{
    return [NSString stringWithFormat:@"_OBJC_METACLASS_$_%@",self.nameOfClass];
}

-(NSString*)superclassMetaclassSymbolName
{
    return [NSString stringWithFormat:@"_OBJC_METACLASS_$_%@",self.nameOfSuperClass];
}

-(void)writeROPartOnSection:(MPWMachOSectionWriter*)classROWriter symbolName:(NSString*)roClassPartSymbol symbolNameOfClassName:(NSString*)symbolNameOfName instanceSize:(int)instanceSize flags:(int)flags methods:(NSString*)methodListSymbol
{
    Mach_O_Class_RO roClassPart={};
    long name_ptr_offset = ((void*)&roClassPart.name) - ((void*)&roClassPart);
    long method_ptr_offset = ((void*)&roClassPart.methods) - ((void*)&roClassPart);
    
    bzero(&roClassPart, sizeof roClassPart);
    roClassPart.flags=flags;
    //    NSLog(@"offset of RO Part for %@: %ld",roClassPartSymbol,[classROWriter length]);
    [classROWriter declareGlobalSymbol:roClassPartSymbol];
    [classROWriter addRelocationEntryForSymbol:symbolNameOfName atOffset:classROWriter.length + name_ptr_offset];
    if ( methodListSymbol) {
        [classROWriter addRelocationEntryForSymbol:methodListSymbol atOffset:classROWriter.length + method_ptr_offset];
    }
    roClassPart.instanceSize = instanceSize;
    [classROWriter appendBytes:&roClassPart length:sizeof roClassPart];
}

-(MPWMachOSectionWriter*)objcConstWriter
{
    return [self.writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_const" flags:0];
}

-(MPWMachOSectionWriter*)objcMethNameWriter
{
    MPWMachOSectionWriter *writer = [self.writer addSectionWriterWithSegName:@"__TEXT" sectName:@"__objc_methname" flags:0];
    writer.flags = S_CSTRING_LITERALS;
    return writer;
}

-(MPWMachOSectionWriter*)objcMethTypeWriter
{
    return [self.writer addSectionWriterWithSegName:@"__TEXT" sectName:@"__objc_methtype" flags:0];
}

-(void)writeRWPartOnSection:(MPWMachOSectionWriter*)classWriter symbolName:(NSString*)classPartSymbol roPartSymbol:(NSString*)roClassPartSymbol metaclassSymbol:metaclassSymbol superclassSymbol:(NSString*)superclassSymbol
{
    Mach_O_Class classInfo={};
    long ro_ptr_offset = ((void*)&classInfo.data) - ((void*)&classInfo);
    long meta_ptr_offset = ((void*)&classInfo.isa) - ((void*)&classInfo);
    long superclass_ptr_offset = ((void*)&classInfo.superclass) - ((void*)&classInfo);
    long cache_ptr_offset = ((void*)&classInfo.cache) - ((void*)&classInfo);
    
    [classWriter declareGlobalSymbol:classPartSymbol];
    [classWriter addRelocationEntryForSymbol:roClassPartSymbol atOffset:classWriter.length + ro_ptr_offset];
    [classWriter addRelocationEntryForSymbol:metaclassSymbol atOffset:classWriter.length + meta_ptr_offset];
    [classWriter addRelocationEntryForSymbol:@"__objc_empty_cache" atOffset:classWriter.length + cache_ptr_offset];
    
    [self.writer declareExternalSymbol:superclassSymbol];
    [classWriter addRelocationEntryForSymbol:superclassSymbol atOffset:classWriter.length + superclass_ptr_offset];
    [classWriter appendBytes:&classInfo length:sizeof classInfo];
}


-(void)writeClass
{
    MPWMachOWriter* writer = self.writer;
    
    NSString *testclassNameSymbolName=[self classNameSymbolName];
    
    //  class name goes in its own section
    
    [writer declareExternalSymbol:@"__objc_empty_cache"];
    MPWMachOSectionWriter *classNameWriter = [writer addSectionWriterWithSegName:@"__TEXT" sectName:@"__objc_classname" flags:0];
    [classNameWriter declareGlobalSymbol:testclassNameSymbolName];
    [classNameWriter writeNullTerminatedString:self.nameOfClass];
    
    // RO Part
    
    NSString *roClassPartSymbol = [self roClassPartSymbol];
    MPWMachOSectionWriter *classROWriter = self.objcConstWriter;
    [self writeROPartOnSection:classROWriter symbolName:roClassPartSymbol symbolNameOfClassName:testclassNameSymbolName instanceSize:self.instanceSize flags:0 methods:self.instanceMethodListSymbol] ;
    
    // RO Metaclass Part
    
    NSString *metaROSymbol = [self roMetaClassPartSymbol];
    [self writeROPartOnSection:classROWriter symbolName:metaROSymbol symbolNameOfClassName:testclassNameSymbolName instanceSize:40 flags:1 methods:nil];
    
    
    
    // RW Part
    
    MPWMachOSectionWriter *classDataWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_data" flags:0];
    NSString *classPartSymbol = [self classPartSymbol];
    NSString *metaclassSymbol = [self metaclassSymbolName];
    NSString *superclassSymbol = [self superclassSymbolName];
    NSString *superclassMetaclassSymbol = [self superclassMetaclassSymbolName];
    [self.writer declareExternalSymbol:superclassSymbol];
    [self.writer declareExternalSymbol:superclassMetaclassSymbol];
    
    
    [self writeRWPartOnSection:classDataWriter symbolName:metaclassSymbol roPartSymbol:metaROSymbol metaclassSymbol:superclassMetaclassSymbol superclassSymbol:superclassMetaclassSymbol];
    [self writeRWPartOnSection:classDataWriter symbolName:classPartSymbol roPartSymbol:roClassPartSymbol metaclassSymbol:metaclassSymbol superclassSymbol:superclassSymbol];
    
    
    // Pointers
    
    MPWMachOSectionWriter *classListWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_classlist" flags:0];
    char zerobytes[80];
    memset(zerobytes,0,80);
    [classListWriter addRelocationEntryForSymbol:classPartSymbol atOffset:0];
    [classListWriter appendBytes:zerobytes length:8];
    
}

-(void)writeMethodListForMethodNames:(NSArray<NSString*>*)names types:(NSArray<NSString*>*)types functions:(NSArray<NSString*>*)functionSymbols methodListSymbol:(NSString*)methodListSymbol
{
    int numberOfMethods = names.count;

    int methodListSize = sizeof(BaseMethods) + (numberOfMethods * sizeof(MethodEntry));
    BaseMethods *methods = calloc( 1, methodListSize);
    methods->count = numberOfMethods;
    methods->entrysize = 24;
    MPWMachOSectionWriter *methNameWriter=self.objcMethNameWriter;
    MPWMachOSectionWriter *methTypeWriter=self.objcMethTypeWriter;
    MPWMachOSectionWriter *objcConstWriter=self.objcConstWriter;


    for (int i=0;i<numberOfMethods;i++) {
        NSString *methodNameSymbol = [NSString stringWithFormat:@"__METHOD_NAME_%@_%d",self.nameOfClass,i];
        NSString *methodTypeSymbol = [NSString stringWithFormat:@"__METHOD_TYPE_%@_%d",self.nameOfClass,i];
        


        [methNameWriter declareGlobalSymbol:methodNameSymbol];
        [methNameWriter writeNullTerminatedString:names[i]];
        
        [methTypeWriter declareGlobalSymbol:methodTypeSymbol];
        [methTypeWriter writeNullTerminatedString:types[i]];
        
        
        long nameInMethodOffset=((void*)&(methods->methods[i].name))-(void*)methods;
        [objcConstWriter addRelocationEntryForSymbol:methodNameSymbol atOffset:(int)nameInMethodOffset];
        long typeInMethodOffset=((void*)&(methods->methods[i].type))-(void*)methods;
        [objcConstWriter addRelocationEntryForSymbol:methodTypeSymbol atOffset:(int)typeInMethodOffset];
        long impInMethodOffset=((void*)&(methods->methods[i].imp))-(void*)methods;
        [objcConstWriter addRelocationEntryForSymbol:functionSymbols[i] atOffset:(int)impInMethodOffset];
    }
    
    [objcConstWriter declareGlobalSymbol:methodListSymbol];
    [objcConstWriter appendBytes:methods length:methodListSize];
    
}

-(void)writeInstanceMethodListForMethodNames:(NSArray<NSString*>*)names types:(NSArray<NSString*>*)types functions:(NSArray<NSString*>*)functionSymbols
{
    NSString *methodListSymbol = [NSString stringWithFormat:@"__INSTANCEMETHOD_LIST_%@",self.nameOfClass];
    self.instanceMethodListSymbol=methodListSymbol;
    [self writeMethodListForMethodNames:names types:types functions:functionSymbols methodListSymbol:methodListSymbol];
}


@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"

@implementation MPWMachOClassWriter(testing) 

+(void)testWriteSimpleClassAndCheckManually
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    [writer addTextSectionData:[self frameworkResource:@"add" category:@"aarch64"]];

    MPWMachOClassWriter *classWriter = [[MPWMachOClassWriter alloc] initWithWriter:writer];
    classWriter.nameOfClass = @"TestClass";
    
    NSString *testclassNameSymbolName = [classWriter classNameSymbolName];
    classWriter.instanceSize = 8;

    [classWriter writeClass];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/class_via_writer.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [MPWMachOReader readerWithData:macho];
    INTEXPECT( machoReader.numSections, 5,@"number of sections");
    
    int classNameSymbolEntry = [machoReader indexOfSymbolNamed:testclassNameSymbolName];
    INTEXPECT(classNameSymbolEntry,1,@"symtab entry");
    
    //  read classname
    
    MPWMachOSection *classnameSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:classNameSymbolEntry]];
    EXPECTNOTNIL(classnameSection, @"have a class name section");
    IDEXPECT(classnameSection.sectionName,@"__objc_classname",@"");
    INTEXPECT( [classnameSection strings].count, 1, @"Objective-C classname");
    IDEXPECT( [classnameSection strings].firstObject, @"TestClass", @"Objective-C classname");
    
    // read RO part
    
    int roClassSmbolIndex=[machoReader indexOfSymbolNamed:[classWriter roClassPartSymbol]];
    INTEXPECT(roClassSmbolIndex, 2,@"symbol index");
    
    MPWMachOSection *roClassPartSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:roClassSmbolIndex]];
    const struct Mach_O_Class_RO *roClassPartCheck=[roClassPartSection bytes];
    EXPECTNOTNIL(roClassPartSection, @"objc const section");
    IDEXPECT(roClassPartSection.sectionName,@"__objc_const",@"");
    EXPECTNOTNIL(roClassPartCheck, @"objc const section data");
    INTEXPECT( roClassPartCheck->instanceSize, 8, @"instance size");
    
    //  read classname via RO part
    
    MPWMachORelocationPointer *classNamePtr = [[[MPWMachORelocationPointer alloc] initWithSection:roClassPartSection relocEntryIndex:0] autorelease];
    IDEXPECT( [classNamePtr targetName],@"_TestClass_name",@"");
    
    INTEXPECT( [[classNamePtr section] typeOfRelocEntryAt:0],0,@"");
    INTEXPECT( [classNamePtr targetOffset],0,@"target offset");
    NSString *className = [[classNamePtr targetPointer] stringValue];
    IDEXPECT( className,@"TestClass",@"");
    
    // read data part (and find RO part)
    
    int rwClassSmbolIndex=[machoReader indexOfSymbolNamed:[classWriter classPartSymbol]];
//    INTEXPECT(rwClassSmbolIndex, 5,@"symbol index"); //  was 2, now 5, not sure this is stable
    MPWMachOSection *rwClassPartSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:rwClassSmbolIndex]];
    MPWMachORelocationPointer *roClassViaRWPointer = [[[MPWMachORelocationPointer alloc] initWithSection:rwClassPartSection relocEntryIndex:0] autorelease];
//    IDEXPECT( [roClassViaRWPointer targetName],@"__OBJC_CLASS_RO_TestClass",@"RO part of class def via RW part");
}

+(void)testWriteSimpleClassAndCheckViaClassReader
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    [writer addTextSectionData:[self frameworkResource:@"add" category:@"aarch64"]];

    MPWMachOClassWriter *classWriter = [[MPWMachOClassWriter alloc] initWithWriter:writer];
    classWriter.nameOfClass = @"TestClass";
    classWriter.nameOfSuperClass = @"NSObject";
    classWriter.instanceSize = 24;
    
    [classWriter writeClass];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/testclass.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [MPWMachOReader readerWithData:macho];
//    NSLog(@"relocations for class2_via_writer.o:");
//    [machoReader dumpRelocationsOn:[MPWByteStream Stderr]];
    MPWMachOClassReader *reader=[machoReader classReaders].firstObject;
    IDEXPECT(reader.nameOfClass,@"TestClass",@"");
    INTEXPECT(reader.instanceSize,24,@"instance size");
    IDEXPECT(reader.superclassPointer.targetName,@"_OBJC_CLASS_$_NSObject",@"superclass pointer");
    INTEXPECT(reader.superclassPointer.targetSectionIndex ,0,@"");
    IDEXPECT( reader.cachePointer.targetName,@"__objc_empty_cache",@"name of cache ptr");

    MPWMachOClassReader *metaclassReader=[reader metaclassReader];
    INTEXPECT(metaclassReader.instanceSize,40,@"class size");
}

+(void)testWriteClassWithOneInstanceMethod
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];

    NSString *methodName = @"method";
    NSString *methodTypeString = @"@:";
    NSString *methodSymbolName = @"-[TestClass method]";

    [writer.textSectionWriter declareGlobalTextSymbol:methodSymbolName];
    MPWARMObjectCodeGenerator *g=[MPWARMObjectCodeGenerator stream];
    g.symbolWriter = writer;
    g.relocationWriter = writer.textSectionWriter;
    [g generateFunctionNamed:methodSymbolName body:^(MPWARMObjectCodeGenerator *gen) {
        [g generateMessageSendToSelector:@"hash"];
        [gen generateAddDest:0 source:0 immediate:200];
    }];
    NSData *d=(NSData*)[g target];

    [writer addTextSectionData:d];
    
    
    
    
    MPWMachOClassWriter *classWriter = [[MPWMachOClassWriter alloc] initWithWriter:writer];
    classWriter.nameOfClass = @"TestClass";
    classWriter.nameOfSuperClass = @"NSObject";
    classWriter.instanceSize = 8;
 
    [classWriter writeInstanceMethodListForMethodNames:@[methodName] types:@[ methodTypeString ] functions:@[ methodSymbolName ]];
    
    [classWriter writeClass];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/testclass-with-method.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [MPWMachOReader readerWithData:macho];
    MPWMachOClassReader *reader=[machoReader classReaders].firstObject;
    IDEXPECT(reader.nameOfClass,@"TestClass",@"");
    INTEXPECT(reader.instanceSize,8,@"instance size");
    INTEXPECT(reader.numberOfMethods,1, @"number of methods");
    INTEXPECT(reader.methodEntrySize,24, @"entry size");

    IDEXPECT([[[reader methodNameAt:0] targetPointer] stringValue],@"method",@"Method name");
    IDEXPECT([[[reader methodTypesAt:0] targetPointer] stringValue],@"@:",@" Method type");
    IDEXPECT([[reader methodCodeAt:0] targetName],methodSymbolName,@"Symbol for the start of the actual method code");
    int symbolNumberOfHashMessageStub = [machoReader indexOfSymbolNamed:@"_objc_msgSend$hash"];
    EXPECTTRUE(symbolNumberOfHashMessageStub>=0,@"should have _objc_msgSend$hash somewhere in the symbol table");
}


+(NSArray*)testSelectors
{
   return @[
       @"testWriteSimpleClassAndCheckManually",
       @"testWriteSimpleClassAndCheckViaClassReader",
       @"testWriteClassWithOneInstanceMethod",
			];
}

@end
