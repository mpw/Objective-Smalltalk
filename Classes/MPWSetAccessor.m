//
//  MPWSetAccessor.m
//  Arch-S
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWSetAccessor.h"
#import "MPWInstanceVariable.h"
#import "MPWMethodCallBack.h"
@implementation MPWSetAccessor



-(NSString*)objcMessageName
{
    NSString *varName = [ivarDef name];
    NSString *upperCasedVarName;
    upperCasedVarName = [[[varName substringToIndex:1] uppercaseString] stringByAppendingString:[varName substringFromIndex:1]];
    return [NSString stringWithFormat:@"set%@:",upperCasedVarName];
}

-(NSString*)declarationString
{
    return [NSString stringWithFormat:@"<void>%@newObject",[self objcMessageName]];
}

-evaluateOnObject:target parameters:parameters
{
	id value=[parameters objectAtIndex:0];
	[ivarDef setValue:value inContext:target];
	return value;
}
#define pointerToVarInObject( anObject ,offset)  ((id*)(((char*)anObject) + offset))

#ifndef __clang_analyzer__
// This leaks because we are installing into the runtime, can't remove after

-(void)installInClass:(Class)aClass
{
    SEL aSelector=NSSelectorFromString([self objcMessageName]);
    int ivarOffset = (int)[ivarDef offset];
    void (^setterBlock)(id object,id arg) = ^void(id object,id arg) {
        id *p=pointerToVarInObject(object,ivarOffset);
        if ( *p != arg ) {
            [*p release];
            [arg retain];
            *p=arg;
        }
    };
    IMP getterImp=imp_implementationWithBlock(setterBlock);
    class_addMethod(aClass, aSelector, getterImp, "@@:@" );
    
}

#endif



@end
