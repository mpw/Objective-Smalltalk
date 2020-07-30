//
//  MPWMethodStore.m
//  MPWTalk
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "MPWMethodStore.h"

#import "MPWMethodHeader.h"
#import "MPWMethodCallBack.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodType.h"
#import "MPWMethod.h"
#import "MPWStCompiler.h"
#import "MPWClassMethodStore.h"
#import "MPWClassMirror.h"

@implementation MPWMethodStore


objectAccessor(NSMutableDictionary, classes, setClasses)
objectAccessor(NSMutableDictionary, metaClasses, setMetaClasses)
idAccessor( typeDict, setTypeDict )
scalarAccessor( id , compiler , setCompiler )

-(void)addMethodType:aMethodType
{
    [typeDict setObject:aMethodType forKey:[aMethodType typeName]];
}

-(void)initializeMethodTypes
{
	[self addMethodType:[MPWMethodType methodTypeWithName:@"Smalltalk" className:@"MPWScriptedMethod"]];
    
}

-initWithCompiler:aCompiler
{
    self=[super init];
    
    [self setClasses:[NSMutableDictionary dictionary]];
    [self setMetaClasses:[NSMutableDictionary dictionary]];

    
	[self setTypeDict:[NSMutableDictionary dictionary]];
	[self initializeMethodTypes];
	[self setCompiler:aCompiler];
    return self;
}


-(MPWClassMethodStore*)classStoreForName:(NSString*)name
{
    NSLog(@"-[MPWMethodStore classStoreForName: %@]",name);
    if (!name) {
        return nil;
    }
    MPWClassMethodStore *theClass=[self classes][name];
    if ( !theClass ) {
        MPWClassMirror *mirror = [MPWClassMirror mirrorWithClassNamed:name];
        theClass=[[[MPWClassMethodStore alloc] initWithClassMirror:mirror compiler:[self compiler]] autorelease];
        [self classes][name]=theClass;
    }
    return theClass;
}

-(MPWClassMethodStore*)metaClassStoreForName:(NSString*)name
{
    MPWClassMethodStore *theClass=[self metaClasses][name];
    if ( !theClass ) {
        MPWClassMirror *mirror = [MPWClassMirror mirrorWithMetaClassNamed:name];
        theClass=[[[MPWClassMethodStore alloc] initWithClassMirror:mirror compiler:[self compiler]] autorelease];
        [self metaClasses][name]=theClass;
    }
    return theClass;
}

-compile:aMethodString
{
	return [[self compiler] compile:aMethodString];
}


-methodTypeForTypeName:typeName
{
	return [[self typeDict] objectForKey:typeName];
}

-allTypeNames
{
	return [[self typeDict] allKeys];
}


//-(NSDictionary*)externalizeScriptsForClass:(NSString*)className
//{
//    NSDictionary *methodDict = [self methodDictionaryForClassNamed:className];
//    NSArray* methods = [methodDict allValues];
//    NSArray* methodHeaders = (NSArray*)[[methods collect] header];
//    NSArray* methodHeaderStrings = (NSArray*)[[methodHeaders collect] headerString];
//    NSArray* scripts = [[methods collect] script];
//    return [NSDictionary dictionaryWithObjects:scripts forKeys:methodHeaderStrings];
//}

-(NSDictionary*)externalScriptDict
{
	NSMutableDictionary *externalDict=[NSMutableDictionary dictionary];
	NSArray *allClasses = [self classesWithScripts];
    
    for ( NSString *className in allClasses) {
        NSMutableDictionary *perClassDict=[NSMutableDictionary dictionary];
        perClassDict[@"instanceMethods"] = [[self classStoreForName:className] externalMethodDict];
        perClassDict[@"classMethods"] = [[self metaClassStoreForName:className] externalMethodDict];
        externalDict[className]=perClassDict;
    }
	return externalDict;
}

-(void)defineMethodsInExternalMethodDict:(NSDictionary*)dict forClass:(NSString*)className
{
//    NSLog(@"define methods for class: %@ in dict: %@ for class: %@",className,dict,className);
    if ( dict[@"instanceMethods"]) {
        [[self classStoreForName:className] defineMethodsInExternalMethodDict:dict[@"instanceMethods"]];
        [[self metaClassStoreForName:className] defineMethodsInExternalMethodDict:dict[@"classMethods"]];
    } else {
        [[self classStoreForName:className] defineMethodsInExternalMethodDict:dict];
    }
}

-(void)installMethods
{
    [[[[self classes] allValues] do] installMethods];
    [[[[self metaClasses] allValues] do] installMethods];
}

-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict
{
	NSArray* classNames = [scriptDict allKeys];
	NSArray* localMethodDicts = [[scriptDict collect] objectForKey:[classNames each]];
	[[self do] defineMethodsInExternalMethodDict:[localMethodDicts each] forClass:[classNames each]];
//    NSLog(@"=== after MethdStore defineMethodsInExternalDict");
}


-(NSArray*)classesWithScripts
{
	return [[self classes] allKeys];
}


-(NSArray*)methodNamesForClassName:(NSString*)className
{
	return [[self classStoreForName:className] allMethodNames];
}

-methodForClass:(NSString*)className name:(NSString*)methodName
{
    return [[self classStoreForName:className] methodForName:methodName];
}

-methodWithClass:(Class)methodClass header:header body:body
{
	id method = [[[methodClass alloc] init] autorelease];
	[method setContext:[self compiler]];
	[method setScript:body];
	[method setMethodHeader:header];
	return method;
}



-(MPWScriptedMethod*)scriptedMethodWithHeader:header body:body
{
	return [self methodWithClass:[MPWScriptedMethod class] header:header body:body];
}


-(void)installMethod:(MPWScriptedMethod*)method inClass:(NSString*)className
{
    [[self classStoreForName:className] installMethod:method];
}

-(void)installMethod:(MPWScriptedMethod*)method inMetaClass:(NSString*)className
{
    [[self metaClassStoreForName:className] installMethod:method];
}


-(void)addMethodOnly:(MPWScriptedMethod*)method forClass:(NSString*)className
{
    [[self classStoreForName:className] addMethod:method];
}

-(void)addMethod:(MPWScriptedMethod*)method forClass:(NSString*)className
{
//	[self addMethodOnly:method forClass:className];
	[self installMethod:method inClass:className];
}


-(void)addScript:(NSString*)scriptString forClass:(NSString*)className methodHeader:(MPWMethodHeader*)header
{
	[self addMethod:[self scriptedMethodWithHeader:header body:scriptString] forClass:className];
}


-(void)addScript:(NSString*)scriptString forClass:(NSString*)className methodHeaderString:(NSString*)headerString
{
    [[self classStoreForName:className] installMethodString:scriptString withHeaderString:headerString];
}

-(void)addScript:(NSString*)scriptString forMetaClass:(NSString*)className methodHeaderString:(NSString*)headerString
{
    [[self metaClassStoreForName:className] installMethodString:scriptString withHeaderString:headerString];
}

-(void)fileout:(MPWByteStream*)s
{
    for (NSString *className in [[self classes] allKeys]) {
        NSLog(@"=== write class: %@",className);
        [s writeString:@"class "];
        [s writeString:className];
        [s writeString:@" : "];
        Class *c=NSClassFromString(className);
        Class *superclass=[c superclass];
        NSString *superclassName=NSStringFromClass(superclass);
        [s writeString:superclassName];
        [s writeString:@"\n{\n"];
        NSArray *methodNames = [[self methodNamesForClassName:className] sortedArrayUsingSelector:@selector(compare:)];
        for ( NSString *methodName in methodNames) {
            NSLog(@" -- write method: %@",methodName);
            MPWScriptedMethod *method=[self methodForClass:className name:methodName];
            MPWMethodHeader *header=[method methodHeader];
            [s writeString:@"-"];
            [s writeString:[header headerString]];
            [s writeString:@" {\n"];
            [s writeString:[method script]];
            [s writeString:@"\n}\n"];
        }
        [s writeString:@"\n}\n"];
    }
}

-(void)dealloc
{
 	[classes release];
	[metaClasses release];
    [typeDict release];
    [super dealloc];
}

@end

@interface MPWMethodStore(fakeTestInterfaces)

-myMethodStoreTestMul:(int)a;

@end


@implementation MPWMethodStore(testing)

+store
{
    return [[[self alloc] initWithCompiler:[[[MPWStCompiler alloc] init] autorelease]] autorelease];
}

#if !TARGET_OS_IPHONE

+(void)testWriteSingleMethodClass
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    MPWMethodStore *store=[compiler methodStore];
    EXPECTNIL(NSClassFromString(@"MPWMethodWriterTestClass1"), @"class not defined");
    [compiler evaluateScriptString:@"class  MPWMethodWriterTestClass1 : NSObject { -answer { 42. } }. "];
    EXPECTNOTNIL(NSClassFromString(@"MPWMethodWriterTestClass1"), @"class defined");
    INTEXPECT([[store classes] count],1,@"number of classes defined");
    MPWByteStream *s=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [store fileout:s];
    NSString *got=[s target];

    // FIXME / WAITFORFIX:  MPWScriptedMethods created by MPWStCompiler do not contain the method source

    NSString *expected=@"class MPWMethodWriterTestClass1 : NSObject\n{\n-answer {\n 42. \n}\n\n}\n";
    NSLog(@"got: '%@'",got);
    NSLog(@"expected: '%@'",expected);

    EXPECTTRUE([got hasPrefix:expected], @"matches as far as it goes");
    IDEXPECT(got,expected,@"fileout");
}

+testSelectors
{
    return @[
        @"testWriteSingleMethodClass",
    ];
}
#endif
@end
