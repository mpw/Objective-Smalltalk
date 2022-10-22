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

@interface MPWMachOClassWriter()

@property (nonatomic,strong) MPWMachOWriter* writer;
@property (nonatomic,strong) NSString* nameOfClass;
@property (nonatomic,assign) int instanceSize;

@end

@implementation MPWMachOClassWriter

-(instancetype)initWithWriter:(MPWMachOWriter*)writer
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

-(NSString*)classPartSymbol
{
    return [NSString stringWithFormat:@"_OBJC_CLASS_%@",self.nameOfClass];
}


-(void)writeClass
{
    MPWMachOWriter* writer = self.writer;
    
    NSString *testclassNameSymbolName=[self classNameSymbolName];
    [writer addTextSectionData:[self frameworkResource:@"add" category:@"aarch64"]];
    
    //  class name goes in its own section
    
    MPWMachOSectionWriter *classNameWriter = [writer addSectionWriterWithSegName:@"__TEXT" sectName:@"__objc_classname" flags:0];
    [classNameWriter declareGlobalSymbol:testclassNameSymbolName];
    [classNameWriter writeNullTerminatedString:self.nameOfClass];
    
    // RO Part
    
    MPWMachOSectionWriter *classROWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_const" flags:0];
    NSString *roClassPartSymbol = [self roClassPartSymbol];
    Mach_O_Class_RO roClassPart={};
    long name_ptr_offset = ((void*)&roClassPart.name) - ((void*)&roClassPart);
    
    [classROWriter addRelocationEntryForSymbol:testclassNameSymbolName atOffset:classROWriter.length + name_ptr_offset];
    roClassPart.instanceSize = self.instanceSize;
    [classROWriter declareGlobalSymbol:roClassPartSymbol];
    [classROWriter appendBytes:&roClassPart length:sizeof roClassPart];
    
    // RW Part
    
    MPWMachOSectionWriter *classDataWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_data" flags:0];
    NSString *classPartSymbol = [self classPartSymbol];
    Mach_O_Class classInfo={};
    long ro_ptr_offset = ((void*)&classInfo.data) - ((void*)&classInfo);
    [classDataWriter declareGlobalSymbol:classPartSymbol];
    [classDataWriter addRelocationEntryForSymbol:roClassPartSymbol atOffset:classDataWriter.length + ro_ptr_offset];
    [classDataWriter appendBytes:&classInfo length:sizeof classInfo];
    
    // Pointers
    
    MPWMachOSectionWriter *classListWriter = [writer addSectionWriterWithSegName:@"__DATA" sectName:@"__objc_classlist" flags:0];
    char zerobytes[80];
    memset(zerobytes,0,80);
    [classListWriter addRelocationEntryForSymbol:classPartSymbol atOffset:0];
    [classListWriter appendBytes:zerobytes length:8];

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
    
    MPWMachOClassWriter *classWriter = [[MPWMachOClassWriter alloc] initWithWriter:writer];
    classWriter.nameOfClass = @"TestClass";
    
    NSString *testclassNameSymbolName = [classWriter classNameSymbolName];
    classWriter.instanceSize = 8;

    [classWriter writeClass];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/class_via_writer.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [MPWMachOReader readerWithData:macho];
    INTEXPECT( machoReader.numSections, 6,@"number of sections");
    
    int classNameSymbolEntry = [machoReader indexOfSymbolNamed:testclassNameSymbolName];
    INTEXPECT(classNameSymbolEntry,0,@"symtab entry");
    
    //  read classname
    
    MPWMachOSection *classnameSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:classNameSymbolEntry]];
    EXPECTNOTNIL(classnameSection, @"have a class name section");
    IDEXPECT(classnameSection.sectionName,@"__objc_classname",@"");
    INTEXPECT( [classnameSection strings].count, 1, @"Objective-C classname");
    IDEXPECT( [classnameSection strings].firstObject, @"TestClass", @"Objective-C classname");
    
    // read RO part
    
    int roClassSmbolIndex=[machoReader indexOfSymbolNamed:[classWriter roClassPartSymbol]];
    INTEXPECT(roClassSmbolIndex, 1,@"symbol index");
    
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
    NSString *className = [NSString stringWithUTF8String:[[classNamePtr targetPointer] bytes]];
    IDEXPECT( className,@"TestClass",@"");
    
    // read data part (and find RO part)
    
    int rwClassSmbolIndex=[machoReader indexOfSymbolNamed:[classWriter classPartSymbol]];
    INTEXPECT(rwClassSmbolIndex, 2,@"symbol index");
    MPWMachOSection *rwClassPartSection=[machoReader sectionAtIndex:[machoReader sectionForSymbolAt:rwClassSmbolIndex]];
    MPWMachORelocationPointer *roClassViaRWPointer = [[[MPWMachORelocationPointer alloc] initWithSection:rwClassPartSection relocEntryIndex:0] autorelease];
    IDEXPECT( [roClassViaRWPointer targetName],@"__OBJC_CLASS_RO_TestClass",@"RO part of class def via RW part");
}

+(void)testWriteSimpleClassAndCheckViaClassReader
{
    MPWMachOWriter *writer = [MPWMachOWriter stream];
    
    MPWMachOClassWriter *classWriter = [[MPWMachOClassWriter alloc] initWithWriter:writer];
    classWriter.nameOfClass = @"AnotherTestClass";
    classWriter.instanceSize = 24;
    
    [classWriter writeClass];
    NSData *macho=[writer data];
    [macho writeToFile:@"/tmp/class2_via_writer.o" atomically:YES];
    
    
    MPWMachOReader *machoReader = [MPWMachOReader readerWithData:macho];
    MPWMachOClassReader *reader=[machoReader classReaders].firstObject;
    IDEXPECT(reader.nameOfClass,@"AnotherTestClass",@"");
    INTEXPECT(reader.instanceSize,24,@"instance size");
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testWriteSimpleClassAndCheckManually",
       @"testWriteSimpleClassAndCheckViaClassReader",
			];
}

@end
