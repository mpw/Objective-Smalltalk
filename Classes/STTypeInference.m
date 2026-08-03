//
//  STTypeInference.m
//  ObjectiveSmalltalk
//
//  Phase 1 of the type-system roadmap: static type-inference skeleton.
//  See STTypeInference.h.
//

#import "STTypeInference.h"
#import <MPWFoundation/MPWTypeDefinition.h>
#import "MPWLiteralExpression.h"
#import "MPWAssignmentExpression.h"
#import "STIdentifierExpression.h"
#import "STIdentifier.h"
#import "STVariableDefinition.h"
#import "STScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWStatementList.h"
#import <objc/runtime.h>

@implementation STTypeContext
{
    NSMutableDictionary<NSString*,MPWTypeDefinition*> *_typesByName;
}

+(instancetype)context
{
    return [[[self alloc] init] autorelease];
}

-init
{
    self=[super init];
    _typesByName=[[NSMutableDictionary alloc] init];
    self.typeProvider=[STRuntimeTypeProvider provider];
    return self;
}

-(MPWTypeDefinition*)idType
{
    return [MPWTypeDefinition idType];
}

-(void)declareName:(NSString*)name type:(MPWTypeDefinition*)type
{
    if ( name && type ) {
        _typesByName[name]=type;
    }
}

-(MPWTypeDefinition*)typeForName:(NSString*)name
{
    return _typesByName[name];
}

+(instancetype)contextForMethod:(STScriptedMethod*)method
{
    STTypeContext *context=[self context];
    MPWMethodHeader *header=method.header;
    for (int i=0;i<header.numArguments;i++) {
        [context declareName:[header argumentNameAtIndex:i] type:[header argumentTypeAtIndex:i]];
    }
    id body=method.methodBody;
    NSArray *statements=[body isKindOfClass:[MPWStatementList class]] ? [body statements] : (body ? @[ body ] : @[]);
    for (id statement in statements) {
        if ( [statement isKindOfClass:[STVariableDefinition class]] ) {
            [context declareName:[statement name] type:[statement type]];
        }
    }
    return context;
}

-(void)dealloc
{
    [_typesByName release];
    [_typeProvider release];
    [_selfType release];
    [super dealloc];
}

@end


@implementation STRuntimeTypeProvider

+(instancetype)provider
{
    return [[[self alloc] init] autorelease];
}

-(MPWTypeDefinition*)returnTypeForSelector:(SEL)selector receiverType:(MPWTypeDefinition*)receiverType
{
    if ( !receiverType ) {
        return nil;
    }
    Class receiverClass=NSClassFromString(receiverType.name);
    if ( !receiverClass ) {
        return nil;
    }
    NSMethodSignature *signature=[receiverClass instanceMethodSignatureForSelector:selector];
    if ( !signature ) {
        return nil;
    }
    const char *returnType=signature.methodReturnType;
    if ( !returnType || !*returnType ) {
        return nil;
    }
    if ( *returnType == 'r' ) {     // const-qualified
        returnType++;
    }
    return [MPWTypeDefinition descriptorForObjcCode:(unsigned char)*returnType];
}

@end


@implementation STExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return [MPWTypeDefinition idType];
}

@end


@implementation MPWLiteralExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    id literal=self.theLiteral;
    if ( [literal isKindOfClass:[NSString class]] ) {
        return [MPWTypeDefinition descriptorForTypeName:@"NSString"];
    }
    if ( [literal isKindOfClass:[NSNumber class]] ) {
        return [MPWTypeDefinition descriptorForTypeName:@"NSNumber"];
    }
    return [MPWTypeDefinition idType];
}

@end


@implementation STIdentifierExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    NSString *name=[[self identifier] identifierName];
    if ( [name isEqual:@"self"] || [name isEqual:@"super"] ) {
        return context.selfType ?: [MPWTypeDefinition idType];
    }
    MPWTypeDefinition *declared=[context typeForName:name];
    return declared ?: [MPWTypeDefinition idType];
}

@end


@implementation MPWAssignmentExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    // Assignment yields the assigned value.
    return [self.rhs resultTypeIn:context];
}

@end


@implementation STVariableDefinition (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return (MPWTypeDefinition*)self.type ?: [MPWTypeDefinition idType];
}

@end
