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
#define pointerToVarInObject( type, anObject ,offset)  ((type*)(((char*)anObject) + offset))

#ifndef __clang_analyzer__
// This leaks because we are installing into the runtime, can't remove after

-(void)installInClass:(Class)aClass
{
    SEL aSelector=NSSelectorFromString([self objcMessageName]);
    const char *typeCode=NULL;
    int ivarOffset = (int)[ivarDef offset];
    IMP getterImp=NULL;
    switch ( ivarDef.objcTypeCode ) {
        case 'd':
        case '@':
            typeCode = "v@:@";
            void (^objectSetterBlock)(id object,id arg) = ^void(id object,id arg) {
                id *p=pointerToVarInObject(id,object,ivarOffset);
                if ( *p != arg ) {
                    [*p release];
                    [arg retain];
                    *p=arg;
                }
            };
            getterImp=imp_implementationWithBlock([objectSetterBlock copy]);
            break;
        case 'i':
        case 'l':
        case 'B':
            typeCode = "v@:l";
            void (^intSetterBlock)(id object,long arg) = ^void(id object,long arg) {
                *pointerToVarInObject(long,object,ivarOffset)=arg;
            };
            getterImp=imp_implementationWithBlock([intSetterBlock copy]);
            break;
        default:
            [NSException raise:@"invalidtype" format:@"Don't know how to generate set accessor for type '%c'",ivarDef.objcTypeCode];
            break;
    }
    if ( getterImp && typeCode ) {
        class_addMethod(aClass, aSelector, getterImp, typeCode );
    }
    
}

#endif



@end
