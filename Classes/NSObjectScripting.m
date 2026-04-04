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


+(void)generateAccessorsFor:(NSString*)varName
{
    MPWInstanceVariableDefinition* ivarDef = [self ivarForName:varName];
    //    NSLog(@"generate accessors for var name '%@', type name: '%@' objc type: %@",varName,[[ivarDef type] name],[ivarDef objcType]);
    id getAccessor = [MPWGetAccessor accessorForInstanceVariable:ivarDef];
    //    NSLog(@"getAcccessor header: %@",[getAccessor methodHeader]);
    id setAccessor = [MPWSetAccessor accessorForInstanceVariable:ivarDef];
    //    NSLog(@"install accessors: %@",varName);
    [getAccessor installInClass:self];
    [setAccessor installInClass:self];
}


@end
