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

#define pointerToVarInObject( anObject ,offset)  ((id*)(((char*)anObject) + offset))

#ifndef __clang_analyzer__
// This leaks because we are installing into the runtime, can't remove after

-(void)installInClass:(Class)aClass
{
    SEL aSelector=NSSelectorFromString([self declarationString]);
    int ivarOffset = (int)[ivarDef offset];
    id (^getterBlock)(id object) = ^id(id object) {
        return *pointerToVarInObject(object,ivarOffset);
    };
    IMP getterImp=imp_implementationWithBlock(getterBlock);
    class_addMethod(aClass, aSelector, getterImp, "@@:" );

}

#endif



@end
