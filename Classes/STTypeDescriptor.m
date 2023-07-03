//
//  STTypeDescriptor.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 30.06.21.
//

#import "STTypeDescriptor.h"
#import <objc/objc.h>

@interface STTypeDescriptor()

@property (nonatomic, assign) unsigned char objcTypeCode;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *cName;

@end


@implementation STTypeDescriptor

static STTypeDescriptor* typesByObjCCode[256];
static NSDictionary *typesBySTName;

+(instancetype)descritptorForObjcCode:(unsigned char)typeCode
{
    return typesByObjCCode[typeCode];
}

+(instancetype)descritptorForSTTypeName:(NSString*)typeName
{
    STTypeDescriptor *td = typesBySTName[typeName];
    if ( !td ) {
        td=[[STTypeDescriptor new] autorelease];
        td.objcTypeCode='@';
        td.name=typeName;
        td.cName=[typeName stringByAppendingString:@"*"];
    }
    return td;
}

typedef struct {
    unsigned char objcTypeCode;
    char *name;
    char *cName;
} STTypeDescriptorStruct;



static STTypeDescriptorStruct definedTypes[]={
    { '@', "id", "id" },
    { 'l', "int", "long" },
    { 'B', "bool", "BOOL" },
    { 'd', "float", "double" },

    { 's', "int", "short" },
    { 'S', "int", "unsigned short" },
    { 'i', "int", "int" },
    { 'q', "long", "long long" },
    { 'I', "int", "unsigned" },
    { 'Q', "long", "unsigned long long" },
    { 'L', "long", "unsigned long" },
    { '*', "str", "char*" },
    { 'v', "void", "void" },
    { ':', "SEL", "SEL" },
    { '#', "class", "Class" },
    { 0, NULL,NULL},
};

+(void)initialize
{
    for (int i=0; definedTypes[i].objcTypeCode;i++) {
        STTypeDescriptor *descriptor=[STTypeDescriptor new];
        descriptor.objcTypeCode=definedTypes[i].objcTypeCode;
        descriptor.name=@(definedTypes[i].name);
        descriptor.cName=@(definedTypes[i].cName);
        typesByObjCCode[definedTypes[i].objcTypeCode]=descriptor;
    }
    unsigned char sttypes[]="@ldvB";
    NSMutableDictionary *st2type=[NSMutableDictionary dictionary];
    for (int i=0;sttypes[i];i++) {
        STTypeDescriptor *t=typesByObjCCode[sttypes[i]];
        st2type[t.name]=t;
    }
    typesBySTName=[st2type copy];
}

+(instancetype)voidType
{
    return [self descritptorForObjcCode:'v'];
}

+(instancetype)idType
{
    return [self descritptorForObjcCode:'@'];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTypeDescriptor(testing) 

+(void)testKnowsAboutID
{
    STTypeDescriptor *idDescriptor=[self descritptorForObjcCode:'@'];
    
    IDEXPECT( idDescriptor.name, @"id", @"stName");
    IDEXPECT( idDescriptor.cName, @"id", @"stName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
}

+(void)testMapsSTIntNameToLong
{
    STTypeDescriptor *idDescriptor=[self descritptorForSTTypeName:@"int"];
    
    IDEXPECT( idDescriptor.name, @"int", @"stName");
    IDEXPECT( idDescriptor.cName, @"long", @"stName");
    INTEXPECT( idDescriptor.objcTypeCode, 'l', @"type code");
}

+(void)testUnknownTypeNamesAreObjects
{
    STTypeDescriptor *idDescriptor=[self descritptorForSTTypeName:@"NSString"];
    
    IDEXPECT( idDescriptor.name, @"NSString", @"stName");
    IDEXPECT( idDescriptor.cName, @"NSString*", @"cName");
    INTEXPECT( idDescriptor.objcTypeCode, '@', @"type code");
}

+(NSArray*)testSelectors
{
   return @[
       @"testKnowsAboutID",
       @"testMapsSTIntNameToLong",
       @"testUnknownTypeNamesAreObjects",
			];
}

@end
