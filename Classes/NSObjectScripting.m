//
//  NSObjectScripting.m
//  Arch-S
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "NSObjectScripting.h"
#import "STCompiler.h"
#import "MPWMethodCallBack.h"
#import "MPWInstanceVariable.h"
#import "MPWSetAccessor.h"
#import "STTypeDescriptor.h"

void amIHereFunc( void )
{
    NSLog(@"I am here");
} 

@implementation NSObject(smalltalkScripting)


-evaluateScript:(NSString*)scriptString
{
	id evaluator=[[[STCompiler alloc] init] autorelease];
	id result;
	result = [evaluator evaluateScript:scriptString onObject:self];
	return result;
}


static BOOL CreateClassDefinition( const char * name, 
								  Class super_class, NSArray *variables  )
{
	Class class=objc_allocateClassPair(super_class,  name, 0);
	for (MPWInstanceVariable* ivar in variables) {
		class_addIvar(class, [[ivar name] cStringUsingEncoding:NSASCIIStringEncoding], sizeof(id), log2(sizeof(id)), [[ivar objcType] UTF8String]);

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
                STTypeDescriptor *type=[STTypeDescriptor descritptorForObjcCode:ivar_getTypeEncoding(ivar)[0]];
				varDescription = [[[MPWInstanceVariable alloc] initWithName:[NSString stringWithCString:ivar_getName(ivar) encoding:NSASCIIStringEncoding]
																	 offset: (int)ivar_getOffset(ivar) 
																	   type:type]
								  autorelease];
				[varNames addObject:varDescription];
			}
		}
	}
}



#ifndef __clang_analyzer__
// This 'leaks' because we are installing into the runtime, can't remove after

+(BOOL)createSubclassWithName:(NSString*)className instanceVariableArray:(NSArray*)vars
{
    int len= (int)[className length]+1;
    char *class_name = malloc( len );
    [className getCString:class_name maxLength:len encoding:NSASCIIStringEncoding];
    return CreateClassDefinition( class_name, self , vars );
}

+(BOOL)createSubclassWithName:(NSString*)className instanceVariables:(NSString*)varsAsString
{
    NSArray *varNames=[varsAsString componentsSeparatedByString:@" "];\
    NSMutableArray *variableDefinitions=[NSMutableArray array];
    for ( NSString *name in varNames ) {
        MPWInstanceVariable *theVar=[[[MPWInstanceVariable alloc] initWithName:name offset:0 type:[STTypeDescriptor descritptorForObjcCode:'@']] autorelease];
        [variableDefinitions addObject:theVar];
    }
    return [self createSubclassWithName:className instanceVariableArray:variableDefinitions];
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

+(MPWInstanceVariable*)ivarForName:(NSString*)name
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
    MPWInstanceVariable* ivarDef = [self ivarForName:varName];
    NSLog(@"generate accessors for var name '%@', type name: '%@' objc type: %@",varName,[[ivarDef type] name],[ivarDef objcType]);
	id getAccessor = [MPWGetAccessor accessorForInstanceVariable:ivarDef];
    NSLog(@"getAcccessor header: %@",[getAccessor methodHeader]);
	id setAccessor = [MPWSetAccessor accessorForInstanceVariable:ivarDef];
	[getAccessor installInClass:self];
	[setAccessor installInClass:self];
}

@end
