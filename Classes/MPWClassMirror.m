//
//  MPWClassMirror.m
//  MPWTest
//
//  Created by Marcel Weiher on 5/29/11.
//  Copyright 2011 Marcel Weiher. All rights reserved.
//

#import "MPWClassMirror.h"
#import "MPWMethodMirror.h"
#import "MPWObjectMirror.h"
#import <objc/runtime.h>


@implementation MPWClassMirror : NSObject


-(instancetype)initWithClass:(Class)aClass
{
	if ( aClass && (self=[super init]) ) {
        theClass=aClass;
    } else {
        [self release];
        self=nil;
    }
	return self;
}

+(instancetype)mirrorWithClass:(Class)aClass
{
    return [[[self alloc] initWithClass:aClass] autorelease];
}

+(instancetype)mirrorWithClassNamed:(NSString*)aClassName
{
    return [self mirrorWithClass:NSClassFromString(aClassName)];
}

+(instancetype)mirrorWithMetaClassNamed:(NSString*)aClassName
{
    return [[self mirrorWithClassNamed:aClassName] metaClassMirror];
}

-(BOOL)isInBundle:(NSBundle*)aBundle
{
	return [NSBundle bundleForClass:[self theClass]] == aBundle;
}

-(NSString*)name
{
	return [NSString stringWithUTF8String:[self cStringClassName]];
}


-(NSArray*)invalidClassNames
{
	static id invalidClassNames=nil;
	if (!invalidClassNames) {
		invalidClassNames=[[NSArray alloc] initWithObjects:
						   @"NSFramework_",
						   @"NSATSGlyphGen",
						   @"_",
						   @"Object",
						   @"NSMessageBuilder",
                           @"OS_xpc_serializer",
                           @"MPWFutureTesting",
                           @"NSCoercionHandler",
                           @"MTLRenderPassStencilAttachmentDescriptor",
                           @"NSKeyValueNonmutatingSetMethodSet",
                           @"NSArrayFilteringTesting",
                           @"OS_",
                           @"NSKeyValueMutatingOrderedSetMethodSet",
                           @"MPWMessageCatcherTesting",
                           @"NSScriptCommandConstructionContext",
                           @"NSLayoutYAxisAnchor",
                           @"NSKeyValueMutatingCollectionMethodSet",
                           @"SuperchainTester2",
                           @"NSObjectInstanceSizeTesting",
                           @"MTLRenderPassDepthAttachmentDescriptor",
                           @"NSStringAdditionsTesting",
                           @"MPWAutocompletionTests",
                           @"MPWClassMirrorSubclassForTesting",
                           @"MPWNamedIdentifier",
                           @"NSLayoutXAxisAnchor",
                           @"MPWDirectForwardingTrampoline",

                           
#if WINDOWS						   
						   @"Object",
						   @"NSProxy",
						   @"MPWSoftPointerProxy",
						   @"MPWTrampoline",
						   @"MPWDirectForwarding",
						   @"Protocol",
						   @"MPWEnum",
						   @"MPWFutu",
						   @"SoftPointer",
						   @"_SoftPointer",
						   @"MPWFastInfoSet",
						   @"MPWXmlWrapper",
						   @"MPWXmlArchiver",
						   @"MPWXmlUnarchiver",
                           @"NSViewServiceApplication",
#endif						   
						   nil];
		
	}
	return invalidClassNames;
}


-(BOOL)isValidClass
{
	//	NSLog(@"checking validity of %@",cName);
#if 1
	Class superclass= [self theSuperclass];
	if ( superclass == nil ) {
		return NO;
	}
	if ( superclass == [NSProxy class] ) {
		return NO;
	}
#endif
	NSString *cName=[self name];
	for ( id name in [self invalidClassNames] ) {
		if ( [cName hasPrefix:name] ) {
			return NO;
		}
	}
	return YES;
}

+(NSArray*)allUsefulClasses
{
	NSMutableArray *useful=[NSMutableArray array];
	for ( MPWClassMirror *mirror in [self allClasses] ) {
		if ( [mirror isValidClass] ) {
			[useful addObject:mirror];
		}
	}
	return useful;
}

+(NSEnumerator*)classEnumerator
{
	return [[self allUsefulClasses] objectEnumerator];
}

-(Class)theClass { return theClass; }

-description { return [NSString stringWithFormat:@"<Mirror for class: %@/%p",[self name],[self theClass]]; }

-(MPWClassMirror*)superclassMirror
{
    Class superclass = [self theSuperclass];
    if ( superclass != theClass) {
        return [[self class] mirrorWithClass:superclass];
    } else {
        return nil;
    }
}

-(BOOL)isEqual:(id)otherMirror
{
	return [self theClass] == [otherMirror theClass];
}

-(NSUInteger)hash { return (NSUInteger)[self theClass]; }

-(BOOL)isSublcassOfClass:(Class)potentialSuperclass
{
	Class checkClass=[self theClass];
	while (checkClass) {
		if ( checkClass==potentialSuperclass ) {
			return YES;
		}
		checkClass=[[self class] superclassOfClass:checkClass];
	}
	return NO;
}

-(BOOL)isSublcassOfMirror:(MPWClassMirror *)potentialSuperclassMirror
{
	return [self isSublcassOfClass: [potentialSuperclassMirror theClass]];
}

-(Class)theSuperclass
{
	return [[self class] superclassOfClass:[self theClass]];
}

-(MPWClassMirror*)createSubclassWithName:(NSString*)name
{
	return [[self class] mirrorWithClass:[self _createClass:[name UTF8String]]];
}

-(MPWClassMirror*)createAnonymousSubclass
{
	NSString *madeUpName=[NSString stringWithFormat:@"%@-subclass-%p-%ld",[self name],self,random()];
	return [self createSubclassWithName:madeUpName];
}

-(id)forwardingTargetForSelector:(SEL)aSelector
{
    return theClass;
}

-(MPWClassMirror*)metaClassMirror
{
    return [[MPWObjectMirror mirrorWithObject:[self theClass]] classMirror];
}



@end

//#if __NEXT_RUNTIME__

#import <objc/runtime.h>

@implementation MPWClassMirror(objc)

-(const char*)cStringClassName
{
	return class_getName( [self theClass] );
}

+(Class)superclassOfClass:(Class)aClass
{
	return class_getSuperclass( aClass );
}

-(Class)_createClass:(const char*)name
{
	Class klass = objc_allocateClassPair([self theClass], name,0);
	objc_registerClassPair(klass);
	return klass;
}


+(NSArray*)allClasses
{
	NSMutableArray *allClasses=[NSMutableArray array];
    int classCount = objc_getClassList(NULL, 0);
    Class classes[classCount + 10];
    int i;
    objc_getClassList(classes, classCount);
	for (i=0;i<classCount;i++) {
		[allClasses addObject:[self mirrorWithClass:classes[i]]];
	}
	return allClasses;
}

-(void)addMethod:(IMP)aMethod forSelector:(SEL)aSelector typeString:(const char*)typestring 
{
	class_addMethod([self theClass], aSelector, aMethod, typestring );
}

-(void)replaceMethod:(IMP)aMethod forSelector:(SEL)aSelector typeString:(const char*)typestring
{
	class_replaceMethod([self theClass], aSelector, aMethod,typestring);
}

static MPWMethodMirror* methodMirrorFromMethod( Method m ) 
{
	MPWMethodMirror *method=[[[MPWMethodMirror alloc] initWithSelector:method_getName(m) typestring:method_getTypeEncoding(m)] autorelease];
	[method setImp:method_getImplementation(m)];
	return method;
}

-(MPWMethodMirror*)methodMirrorForSelector:(SEL)aSelector
{
	return methodMirrorFromMethod(class_getInstanceMethod([self theClass], aSelector)) ;
}

-(NSArray*)methodMirrors
{
	NSMutableArray *methods=[NSMutableArray array];
	unsigned int methodCount=0;
	Method *methodList = class_copyMethodList([self theClass], &methodCount );
	if ( methodList ) {
		int i;
		for (i=0;i<methodCount;i++) {
			[methods addObject:methodMirrorFromMethod(methodList[i] )];
		}
		free(methodList);
	}
	return  methods;
}



@end




//#endif

#import <MPWFoundation/DebugMacros.h>
#import <objc/message.h>
#import "MPWObjectMirror.h"

@interface NSObject(fakeTestingMessages)
-__testMessage;
-(id)__testMessageHi;

@end

@interface MPWClassMirrorSubclassForTesting : MPWClassMirror
@end
@implementation MPWClassMirrorSubclassForTesting
+testSelectors { return @[]; }
@end


//extern id _objc_msgForward(id receiver, SEL sel, ...);
#ifndef GS_API_LATEST

@implementation MPWClassMirror(testing)

-(NSString*)__testMessageHi
{
	return @"Hello added method";
}

-(void)forwardInvocation:(NSInvocation*)inv
{
	NSString *hi=@"hi there";
	[inv setReturnValue:&hi];
}

+(void)testCreatePerObjectSubclassWithMethodAndForwarding
{
	NSObject *hi=[[[NSObject alloc] init] autorelease];
	id result=nil;
	MPWObjectMirror *objectMirror=[MPWObjectMirror mirrorWithObject:hi];
	@try {
		result = [hi __testMessageHi];
	} @catch (id e) {
		;
	}
	EXPECTNIL( result, @"should not have assigned a value");
	MPWClassMirror *mirror=[objectMirror classMirror];
	MPWClassMirror *sub= [mirror createAnonymousSubclass];
	[sub addMethod:[mirror methodForSelector:@selector(__testMessageHi)] forSelector:@selector(__testMessage) typeString:"@@:"];
	[objectMirror setObjectClass:[sub theClass]];
	result = [hi __testMessage];
	IDEXPECT( result, @"Hello added method", @"after addition");
	[sub replaceMethod:_objc_msgForward  forSelector:@selector(__testMessage)  typeString:"@@:"];
	[sub replaceMethod:[mirror methodForSelector:@selector(forwardInvocation:)] forSelector:@selector(forwardInvocation:)  typeString:"@@:"];
	result = [hi __testMessage];
	IDEXPECT(result,@"hi there",@"via invocation");
}

+(void)testCreatePerClassSubclassWithMethodAndForwarding
{
	id result=nil;
	MPWObjectMirror *classObjectMirror=[MPWObjectMirror mirrorWithObject:[NSObject class]];

	MPWClassMirror *mirror=[MPWClassMirror mirrorWithClass:[NSObject class]];
	MPWClassMirror *sub= [mirror createAnonymousSubclass];
	MPWClassMirror *metaclass=[MPWClassMirror mirrorWithClass:object_getClass([sub theClass])];
	[metaclass addMethod:[mirror methodForSelector:@selector(__testMessageHi)] forSelector:@selector(__testMessage)  typeString:"@@:"];
	Class previous = [classObjectMirror setObjectClass:[metaclass theClass]];
	result = [[NSObject class] __testMessage];
	IDEXPECT( result, @"Hello added method", @"after addition");
	EXPECTTRUE( [[NSObject class] respondsToSelector:@selector(__testMessage)],@"should now know my test method")
	[metaclass replaceMethod:_objc_msgForward  forSelector:@selector(__testMessage)  typeString:"@@:"];
	[metaclass replaceMethod:[mirror methodForSelector:@selector(forwardInvocation:)] forSelector:@selector(forwardInvocation:)  typeString:"@@:"];
	result = [[NSObject class] __testMessage];
	IDEXPECT(result,@"hi there",@"via invocation");
	[classObjectMirror setObjectClass:previous];
	EXPECTFALSE( [[NSObject class] respondsToSelector:@selector(__testMessage)],@"should no longer know my test method")
	
}

+(void)testSuperclassMirror
{
    Class theClass=[MPWClassMirrorSubclassForTesting class];
    

    MPWClassMirror *classMirror=[self mirrorWithClass:theClass];
    MPWClassMirror *superclassMirror=[classMirror superclassMirror];
    IDEXPECT([superclassMirror theClass], [MPWClassMirror class], @"superclass matches");
    
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testCreatePerObjectSubclassWithMethodAndForwarding",
            @"testCreatePerClassSubclassWithMethodAndForwarding",
            @"testSuperclassMirror",
			nil];
}

@end

#endif

