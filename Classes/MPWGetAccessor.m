//
//  MPWGetAccessor.m
//  Arch-S
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWGetAccessor.h"
#import "MPWInstanceVariable.h"
#import "MPWMethodHeader.h"
#import "MPWMethodCallBack.h"

@implementation MPWGetAccessor

objectAccessor( MPWInstanceVariable, ivarDef, _setIvarDef )


-declarationString
{
	return [ivarDef name];
}

-(void)setIvarDef:(MPWInstanceVariable*)newIvarDef
{
	[self _setIvarDef:newIvarDef];
	[self setMethodHeader:[MPWMethodHeader methodHeaderWithString:[self declarationString]]];
}

-initWithInstanceVariableDef:(MPWInstanceVariable*)newIvarDef
{
	self = [super init];
	[self setIvarDef:newIvarDef];
	return self;
}

+accessorForInstanceVariable:(MPWInstanceVariable*)ivarDef
{
	return [[[self alloc] initWithInstanceVariableDef:ivarDef] autorelease];
}

+(NSArray*)testSelectors {
	return [NSArray array];
}

-evaluateOnObject:target parameters:parameters
{
	return [ivarDef valueInContext:target];
}

#define pointerToVarInObject( type, anObject ,offset)  ((type*)(((char*)anObject) + offset))

#ifndef __clang_analyzer__
// This leaks because we are installing into the runtime, can't remove after

-(void)installInClass:(Class)aClass
{
    SEL aSelector=NSSelectorFromString([self declarationString]);
    const char *typeCode=NULL;
    int ivarOffset = (int)[ivarDef offset];
    IMP getterImp=NULL;
    switch ( ivarDef.objcTypeCode ) {
        case 'd':
        case '@':
            typeCode = "@@:";
            id (^objectGetterBlock)(id object) = ^id(id object) {
                return *pointerToVarInObject(id,object,ivarOffset);
            };
            getterImp=imp_implementationWithBlock([objectGetterBlock copy]);
            break;
        case 'i':
        case 'l':
        case 'B':
            typeCode = "l@:";
            long (^intGetterBlock)(id object) = ^long(id object) {
                return *pointerToVarInObject(long,object,ivarOffset);
            };
            getterImp=imp_implementationWithBlock([intGetterBlock copy]);
            break;
        default:
            [NSException raise:@"invalidtype" format:@"Don't know how to generate get accessor for type '%c'",ivarDef.objcTypeCode];
            break;
    }
    if ( getterImp && typeCode ) {
        class_addMethod(aClass, aSelector, getterImp, typeCode );
    }

}

#endif



@end
