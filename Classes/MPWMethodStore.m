//
//  MPWMethodStore.m
//  MPWTalk
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MPWMethodStore.h"

#import "MPWMethodHeader.h"
#import "MPWMethodCallBack.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodType.h"
#import "MPWStCompiler.h"


@implementation MPWMethodStore


idAccessor( methodDicts, setMethodDicts )
idAccessor( callbackDicts, setCallbackDicts )
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
	[self setMethodDicts:[NSMutableDictionary dictionary]];
	[self setCallbackDicts:[NSMutableDictionary dictionary]];
	[self setTypeDict:[NSMutableDictionary dictionary]];
	[self initializeMethodTypes];
	[self setCompiler:aCompiler];
    return self;
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


-(NSDictionary*)externalizeScriptsForClass:(NSString*)className
{
	NSDictionary *methodDict = [self methodDictionaryForClassNamed:className];
	NSArray* methods = [methodDict allValues];
	NSArray* methodHeaders = (NSArray*)[[methods collect] header];
	NSArray* methodHeaderStrings = (NSArray*)[[methodHeaders collect] headerString];
	NSArray* scripts = [[methods collect] script];
	return [NSDictionary dictionaryWithObjects:scripts forKeys:methodHeaderStrings];
}

-(NSDictionary*)externalScriptDict
{
	NSMutableDictionary *externalDict=[NSMutableDictionary dictionary];
	NSArray *allClasses = [self classesWithScripts];
	NSArray *classDicts = (NSArray*)[[self collect] externalizeScriptsForClass:[allClasses each]];
	[[externalDict do] setObject:[classDicts each] forKey:[allClasses each]];
	return externalDict;
}

-(void)defineMethodsInExternalMethodDict:(NSDictionary*)dict forClass:(NSString*)className
{
	NSArray *methodHeaders = [dict allKeys];
	NSArray *methodBodies = [[dict collect] objectForKey:[methodHeaders each]];
	[[self do] addScript:[methodBodies each] forClass:className methodHeaderString:[methodHeaders each]];
}

-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict
{
	NSArray* classNames = [scriptDict allKeys];
	NSArray* localMethodDicts = [[scriptDict collect] objectForKey:[classNames each]];
	[[self do] defineMethodsInExternalMethodDict:[localMethodDicts each] forClass:[classNames each]];
    NSLog(@"=== after MethdStore defineMethodsInExternalDict");
}

-methodDictionaryForClassNamed:(NSString*)className
{
	id dict=[[self methodDicts] objectForKey:className];
	if ( dict==nil ) {
		dict=[NSMutableDictionary dictionary];
		[[self methodDicts] setObject:dict forKey:className];
	}
	return dict;
}

-callbackDictionaryForClassNamed:(NSString*)className
{
	id dict=[[self callbackDicts] objectForKey:className];
	if ( dict==nil ) {
		dict=[NSMutableDictionary dictionary];
		[[self callbackDicts] setObject:dict forKey:className];
	}
	return dict;
}

-(NSArray*)classesWithScripts
{
	return [[self methodDicts] allKeys];
}


-(NSArray*)methodNamesForClassName:(NSString*)className
{
	return [[self methodDictionaryForClassNamed:className] allKeys];
}

-methodForClass:(NSString*)className name:(NSString*)methodName
{
	return [[self methodDictionaryForClassNamed:className] objectForKey:methodName];
}

-callbackForClass:(NSString*)className name:(NSString*)methodName
{
	return [[self callbackDictionaryForClassNamed:className] objectForKey:methodName];
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


-(void)installMethod:(MPWMethod*)method inClass:(NSString*)className
{
	id callbackDict = [self callbackDictionaryForClassNamed:className];
	id methodCallback;
	id methodName = [[method methodHeader] methodName];
	methodCallback = [callbackDict objectForKey:methodName];
	if (  [self compiler] ) {
		[method setContext:[self compiler]];
	}
	if ( methodCallback == nil ) {
		methodCallback = [[MPWMethodCallBack alloc] init];
		[methodCallback setMethod:method];
		[methodCallback installInClass:NSClassFromString(className)];
		[callbackDict setObject:methodCallback forKey:methodName];
	} else {
		[methodCallback setMethod:method];
	}
}

-(void)addMethodOnly:(MPWMethod*)method forClass:(NSString*)className
{
	id methodName = [[method methodHeader] methodName];
	id methodDict = [self methodDictionaryForClassNamed:className];
	id callback = [self callbackForClass:className name:methodName];
	[methodDict setObject:method forKey:methodName];
	if ( callback ) {
		[callback setMethod:method];
	}
	
}

-(void)addMethod:(MPWMethod*)method forClass:(NSString*)className
{
	[self addMethodOnly:method forClass:className];
	[self installMethod:method inClass:className];
}


-(void)addScript:(NSString*)scriptString forClass:(NSString*)className methodHeader:(MPWMethodHeader*)header
{
	[self addMethod:[self scriptedMethodWithHeader:header body:scriptString] forClass:className];
}


-(void)addScript:(NSString*)scriptString forClass:(NSString*)className methodHeaderString:headerString
{
	MPWMethodHeader* header = [MPWMethodHeader methodHeaderWithString:headerString];
	[self addScript:scriptString forClass:className methodHeader:header];
}

-(void)encodeWithCoder:aCoder
{
	[super encodeWithCoder:aCoder];
	encodeVar( aCoder, typeDict );
	encodeVar( aCoder, methodDicts );
}

-initWithCoder:aCoder
{
	self = [super initWithCoder:aCoder];
	decodeVar( aCoder, typeDict );
	decodeVar( aCoder, methodDicts );
	[self setCallbackDicts:[NSMutableDictionary dictionary]];
	return self;
}

-(void)installMethodsForClass:(NSString*)aClassName
{
	id methodDict=[self methodDictionaryForClassNamed:aClassName];
	id methods=[methodDict allValues];
	[[self do] installMethod:[methods each]  inClass:aClassName];
}

-(void)installMethods
{
	[[self do] installMethodsForClass:[[[self methodDicts] allKeys] each]];
}

-(void)dealloc
{
 	[methodDicts release];
	[callbackDicts release];
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

+(void)testArchivingWithoutInstallingMethods
{
	MPWMethodStore* store = [self store];
	NSData* encoded;
	MPWMethodStore* decoded;
	[store addMethodOnly:[store scriptedMethodWithHeader:[MPWMethodHeader methodHeaderWithString:@"myMethodStoreTestMul:a"] body:@"self*a."] forClass:@"NSNumber"];
	INTEXPECT( [[store methodDictionaryForClassNamed:@"NSNumber"] count], 1 ,@"number of methods before decoding" );
	encoded = [NSArchiver archivedDataWithRootObject:store];
	decoded = [NSUnarchiver unarchiveObjectWithData:encoded];
	INTEXPECT( [[decoded methodDictionaryForClassNamed:@"NSNumber"] count], 1 ,@"number of methods after decoding" );
}

+(void)testArchivingAndInstallingMethodsAfterwards
{
	MPWMethodStore* store = [self store];
	NSData* encoded;
	MPWMethodStore* decoded;
	id testnumber;
	id resultnumber=nil;
	[store addMethodOnly:[store scriptedMethodWithHeader:[MPWMethodHeader methodHeaderWithString:@"myMethodStoreTestMul:<int>a"] body:@"self*a."] forClass:@"NSNumber"];
	testnumber = [NSNumber numberWithInt:2];
	NS_DURING
		resultnumber = [testnumber myMethodStoreTestMul:3];
	NS_HANDLER
	NS_ENDHANDLER
	IDEXPECT( resultnumber, nil, @"before install:  shouldn't have done anything " );
	encoded = [NSArchiver archivedDataWithRootObject:store];
	decoded = [NSUnarchiver unarchiveObjectWithData:encoded];
	[decoded installMethods];
//	NSLog(@"will multiply");
	resultnumber = [testnumber myMethodStoreTestMul:3];
//	NSLog(@"did multiply");
	INTEXPECT( [resultnumber intValue], 6, @"after install, should have multipled");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
		@"testArchivingWithoutInstallingMethods",
		@"testArchivingAndInstallingMethodsAfterwards",
        nil];
}
#endif
@end
