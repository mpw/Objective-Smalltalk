//
//  MPWMachOClassReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import "MPWMachOClassReader.h"
#import "MPWMachOReader.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"
#import "Mach_O_Structs.h"

@interface MPWMachOClassReader()

@property (nonatomic, strong) MPWMachORelocationPointer *basePointer;

@end


@implementation MPWMachOClassReader


static int offsetOfReadOnlyPointerFromBaseClass() {
    Mach_O_Class c;
    return (void*)&c.data - (void*)&c;
}

static int offsetOfMethodListPointerFromBaseClassRO() {
    Mach_O_Class_RO c;
    return (void*)&c.methods - (void*)&c;
}

static int offsetOfClassNamePointerFromBaseClassRO() {
    Mach_O_Class_RO c;
    return (void*)&c.name - (void*)&c;
}


-(instancetype)initWithPointer:(MPWMachORelocationPointer*)basePointer
{
    self=[super init];
    self.basePointer = basePointer;
    return self;
}

-(NSString*)classSymbolName
{
    return self.basePointer.targetName;
}

-(MPWMachORelocationPointer*)metaclassPointer
{
    return [[self.basePointer targetPointer] relocationPointerAtOffset:0];
}

-(instancetype)metaclassReader
{
    return [[[[self class] alloc] initWithPointer:[self metaclassPointer]] autorelease];
}

-(MPWMachORelocationPointer*)readOnlyPartRelocationPointer
{
    return [[self.basePointer targetPointer] relocationPointerAtOffset:offsetOfReadOnlyPointerFromBaseClass()];
}

-(MPWMachOInSectionPointer*)readOnlyPartSectionPointer
{
    return self.readOnlyPartRelocationPointer.targetPointer;
}

-(NSString*)readOnlyPartSymbolName
{
    return self.readOnlyPartRelocationPointer.targetName;
}

-(MPWMachORelocationPointer*)methodListRelocationPointer
{
    return [[self readOnlyPartSectionPointer] relocationPointerAtOffset:offsetOfMethodListPointerFromBaseClassRO()] ;
}

-(int)instanceSize
{
    const Mach_O_Class_RO *c = [self.readOnlyPartSectionPointer bytes];
    return c->instanceSize;
}

-(int)flags
{
    const Mach_O_Class_RO *c = [self.readOnlyPartSectionPointer bytes];
    return c->flags;
}

-(MPWMachORelocationPointer*)classNameRelocationPointer
{
    return [[self readOnlyPartSectionPointer] relocationPointerAtOffset:offsetOfClassNamePointerFromBaseClassRO()] ;
}


-(NSString*)nameOfClass
{
    MPWMachORelocationPointer *cname=[self classNameRelocationPointer];
    MPWMachOSection *classnameSection=[cname targetSection];
    NSData *data=[classnameSection sectionData];
    long offset = [cname targetOffset];
    NSString *s=[NSString stringWithUTF8String:data.bytes+offset];
    return s;
}


-(NSString*)methodListSymbolName
{
    return self.methodListRelocationPointer.targetName;
}

-(MPWMachOInSectionPointer*)methodListPointer
{
    return self.methodListRelocationPointer.targetPointer;
}

-(const BaseMethods*)methodList
{
    return [self.methodListPointer bytes];
}

-(int)numberOfMethods
{
    return [self methodList]->count;
}

-(int)methodEntrySize
{
    return [self methodList]->entrysize;
}

-(MPWMachORelocationPointer*)methodNameAt:(int)methodIndex
{
    return [self.methodListPointer relocationPointerAtOffset:sizeof(BaseMethods) + (sizeof(MethodEntry)*methodIndex)+0];
}

-(MPWMachORelocationPointer*)methodTypesAt:(int)methodIndex
{
    return [self.methodListPointer relocationPointerAtOffset:sizeof(BaseMethods) + (sizeof(MethodEntry)*methodIndex)+8];
}

-(MPWMachORelocationPointer*)methodCodeAt:(int)methodIndex
{
    return [self.methodListPointer relocationPointerAtOffset:sizeof(BaseMethods) + (sizeof(MethodEntry)*methodIndex)+16];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOClassReader(testing) 

+(instancetype)readerForTestFile:(NSString*)testfile
{
    MPWMachOReader *machoReader=[MPWMachOReader readerForTestFile:testfile];
    MPWMachOClassReader *classreader=[[[self alloc] initWithPointer:machoReader.classPointers[0]] autorelease];
    return classreader;
}

+(void)testReadClass
{
    MPWMachOClassReader *reader=[self readerForTestFile:@"two-classes"];
    IDEXPECT( reader.classSymbolName, @"_OBJC_CLASS_$_SecondClass",@"class symbol");
    IDEXPECT( reader.readOnlyPartSymbolName, @"__OBJC_CLASS_RO_$_SecondClass",@"read only part symbol");
    IDEXPECT( reader.classNameRelocationPointer.targetName, @"l_OBJC_CLASS_NAME_.1",@"class name symbol");
    MPWMachOSection *cnameSection=reader.classNameRelocationPointer.targetSection;
    IDEXPECT( cnameSection.sectionName, @"__objc_classname",@"section name in which class name is stored");
    INTEXPECT( reader.classNameRelocationPointer.targetOffset,11,@"offset");

    IDEXPECT( reader.nameOfClass, @"SecondClass",@"class name");

    INTEXPECT( reader.flags, 0, @"flags for class");
    INTEXPECT( reader.instanceSize, 8, @"instance size of class");
    IDEXPECT( reader.methodListSymbolName, @"__OBJC_$_INSTANCE_METHODS_SecondClass",@"method list symbol");
    INTEXPECT( reader.numberOfMethods, 3,@"number of methods");
    INTEXPECT( reader.methodEntrySize, 24,@"method entry size");
    IDEXPECT( [[reader methodNameAt:0] targetName], @"l_OBJC_METH_VAR_NAME_.2",@"first method name symbol name");
    IDEXPECT( [[reader methodTypesAt:0] targetName], @"l_OBJC_METH_VAR_TYPE_.3",@"first method type encoding symbol name");
    IDEXPECT( [[reader methodCodeAt:0] targetName], @"-[SecondClass hi]",@"first method code symbol name");
    IDEXPECT( [[reader methodNameAt:1] targetName], @"l_OBJC_METH_VAR_NAME_.4",@"second method name symbol name");
    IDEXPECT( [[reader methodTypesAt:1] targetName], @"l_OBJC_METH_VAR_TYPE_.3",@"second method type encoding symbol name");
    IDEXPECT( [[reader methodCodeAt:1] targetName], @"-[SecondClass there]",@"second method code symbol name");
}

+(void)testReadMetaClass
{
    MPWMachOClassReader *baseReader=[self readerForTestFile:@"two-classes"];
    MPWMachORelocationPointer *metaclassPointer = [baseReader metaclassPointer];
    IDEXPECT(metaclassPointer.targetName, @"_OBJC_METACLASS_$_SecondClass",@"meta class symbol name");
    
    
    MPWMachOClassReader *reader = [baseReader metaclassReader];
    IDEXPECT( reader.classSymbolName, @"_OBJC_METACLASS_$_SecondClass",@"class symbol");
    IDEXPECT( reader.readOnlyPartSymbolName, @"__OBJC_METACLASS_RO_$_SecondClass",@"read only part symbol");
    INTEXPECT( reader.flags, 1, @"flags for metaclass");
    INTEXPECT( reader.instanceSize, 40, @"size of class object");
    EXPECTNIL( reader.methodListSymbolName,@"no class methods");
    IDEXPECT( reader.nameOfClass, @"SecondClass",@"class name");
}



+(NSArray*)testSelectors
{
   return @[
       @"testReadClass",
       @"testReadMetaClass"
			];
}

@end
