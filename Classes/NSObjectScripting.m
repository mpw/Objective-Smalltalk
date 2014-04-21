//
//  NSObjectScripting.m
//  MPWTalk
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "NSObjectScripting.h"

#import "MPWMethodCallBack.h"
#import "MPWStCompiler.h"
#import "MPWInstanceVariable.h"
#import "MPWSetAccessor.h"
#import <ObjectiveSmalltalk/MPWGetAccessor.h>

@implementation NSObject(stScripting)


-evaluateScript:(NSString*)scriptString
{
	id evaluator=[[[MPWStCompiler alloc] init] autorelease];
	id result;
	result = [evaluator evaluateScript:scriptString onObject:self];
	return result;
}

#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )

static BOOL CreateClassDefinition( const char * name, 
								  Class super_class, NSArray *varNames  )
{
	Class class=objc_allocateClassPair(super_class,  name, 0);
	for (id varName in varNames) {
		class_addIvar(class, [varName cStringUsingEncoding:NSASCIIStringEncoding], sizeof(id), log2(sizeof(id)), "@");

	}
	objc_registerClassPair(class);
	return YES;
}


static void __collectInstanceVariables( Class aClass, NSMutableArray *varNames )
{
	int i;
	if ( aClass ) {
		unsigned int ivarCount=0;
		Ivar  *ivars=NULL;
		__collectInstanceVariables( [aClass superclass], varNames );
		
		ivars = class_copyIvarList(aClass, &ivarCount);
		if ( ivars  && ivarCount > 0) {
			for (i=0;i < ivarCount; i++ ){
				Ivar ivar=ivars[i];
				MPWInstanceVariable *varDescription;
				varDescription = [[[MPWInstanceVariable alloc] initWithName:[NSString stringWithCString:ivar_getName(ivar) encoding:NSASCIIStringEncoding]
																	 offset: ivar_getOffset(ivar) 
																	   type:[NSString stringWithCString:ivar_getTypeEncoding(ivar) encoding:NSASCIIStringEncoding]]
								  autorelease];
				[varNames addObject:varDescription];
			}
		}
	}
}

#else

static BOOL CreateClassDefinition( const char * name, 
								   Class super_class, NSArray *varNames  )
{
    struct objc_class * meta_class;
    struct objc_class * new_class;
    struct objc_class * root_class;
	int i;
	int extra_space = [varNames count] * sizeof(id);
    //
    // Ensure that the superclass exists and that someone
    // hasn't already implemented a class with the same name
    //
    if (super_class == nil)
    {
        return NO;
    }
    
    if (objc_lookUpClass (name) != nil) 
    {
        return NO;
    }
    // Find the root class
    root_class = super_class;
    while( root_class->super_class != nil )
    {
        root_class = root_class->super_class;
    }
    // Allocate space for the class and its metaclass
    new_class = calloc( 2, sizeof(struct objc_class) );
    meta_class = &new_class[1];
    // setup class
    new_class->isa      = meta_class;
    new_class->info     = CLS_CLASS;
    meta_class->info    = CLS_META;
    //
    // Create a copy of the class name.
    // For efficiency, we have the metaclass and the class itself 
    // to share this copy of the name, but this is not a requirement
    // imposed by the runtime.
    //
    new_class->name = malloc (strlen (name) + 1);
    strcpy ((char*)new_class->name, name);
    meta_class->name = new_class->name;
    //
    // Allocate empty method lists.
    // We can add methods later.
    //
    new_class->methodLists = calloc( 1, sizeof(struct objc_method_list *) );
    *new_class->methodLists = (void*)-1;
    meta_class->methodLists = calloc( 1, sizeof(struct objc_method_list *) );
    *meta_class->methodLists = (void*)-1;
    //
    // Connect the class definition to the class hierarchy:
    // Connect the class to the superclass.
    // Connect the metaclass to the metaclass of the superclass.
    // Connect the metaclass of the metaclass to
    //      the metaclass of the root class.
	new_class->instance_size = super_class->instance_size + extra_space;
    new_class->super_class  = super_class;
    meta_class->super_class = super_class->isa;
    meta_class->isa         = (void *)root_class->isa;
    // Finally, register the class with the runtime.
	if ( [varNames count] >  0 )  {
		int baseOffset = super_class->instance_size;
		new_class->ivars=calloc( 1,sizeof new_class->ivars + (sizeof new_class->ivars->ivar_list[0])*[varNames count]);
		new_class->ivars->ivar_count = [varNames count];
		for ( i=0;i<[varNames count];i++) {
			struct objc_ivar* var = &new_class->ivars->ivar_list[i];
			id name = [varNames objectAtIndex:i];
			var->ivar_name = calloc(1, [name length]+1 );
			[name getCString:var->ivar_name];
			var->ivar_type="@";
			var->ivar_offset=baseOffset;
			baseOffset+=4;
		}
	}
    objc_addClass( new_class ); 
    return YES;
}

static void __collectInstanceVariables( Class aClass, NSMutableArray *varNames )
{
	int i;
	if ( aClass ) {
		__collectInstanceVariables( aClass->super_class, varNames );
		if ( aClass->ivars ) {
			for (i=0;i < aClass->ivars->ivar_count; i++ ){
				struct objc_ivar var=aClass->ivars->ivar_list[i];
				MPWInstanceVariable *varDescription;
				varDescription = [[[MPWInstanceVariable alloc] initWithName:[NSString stringWithCString:var.ivar_name] 
																	 offset: var.ivar_offset 
																	   type:[NSString stringWithCString:var.ivar_type]]
								  autorelease];
				[varNames addObject:varDescription];
			}
		}
	}
}

#endif

#ifndef __clang_analyzer__
// This 'leaks' because we are installing into the runtime, can't remove after

+(BOOL)createSubclassWithName:(NSString*)className instanceVariables:(NSString*)varsAsString
{
	NSArray *vars=[varsAsString componentsSeparatedByString:@" "];\
	int len= [className length]+1;
    char *class_name = malloc( len );
    [className getCString:class_name maxLength:len encoding:NSASCIIStringEncoding];
    return CreateClassDefinition( class_name, self , vars );
}

#endif

+(BOOL)createSubclassWithName:(NSString*)className
{
	return [self createSubclassWithName:className instanceVariables:@""];
}

static id ivarNameCache=nil;
static id ivarsByClassAndName=nil;



+instanceVariables
{
#if 1	
	NSString *className = NSStringFromClass(self);
	NSMutableArray *varNames;
	if ( !ivarNameCache ) {
		ivarNameCache = [[NSMutableDictionary alloc] init];
	}
	varNames = [ivarNameCache objectForKey:className];
	if ( ! varNames  ) {
		varNames = [NSMutableArray array];
		__collectInstanceVariables( self, varNames );
		[ivarNameCache setObject:varNames forKey:className];
	}
	return varNames;
#endif	
}

+ivarForName:(NSString*)name
{
	id className = NSStringFromClass(self);
	id instVarDict=nil;
	if ( !ivarsByClassAndName ) {
		ivarsByClassAndName=[NSMutableDictionary new];
	}
	instVarDict = [ivarsByClassAndName objectForKey:className];
	if ( !instVarDict ) {
		id ivarDefs = [self instanceVariables];
		id names = [[ivarDefs collect] name];
		instVarDict=[NSMutableDictionary dictionaryWithObjects:ivarDefs forKeys:names];
		[ivarsByClassAndName setObject:instVarDict forKey:className];
	}
	return [instVarDict objectForKey:name];
}

+(void)generateAccessorsFor:(NSString*)varName
{
	id ivarDef = [self ivarForName:varName];
	id getAccessor = [MPWGetAccessor accessorForInstanceVariable:ivarDef];
	id setAccessor = [MPWSetAccessor accessorForInstanceVariable:ivarDef];
	[getAccessor installInClass:self];
	[setAccessor installInClass:self];
}

@end
