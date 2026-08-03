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
#import "MPWMessageExpression.h"
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
    // Runtime first (authoritative for statically-known classes), then the
    // hardcoded table (operators and id-receiver primitive extractors).
    self.typeProvider=[STCompositeTypeProvider providerWithProviders:@[
        [STRuntimeTypeProvider provider], [STHardcodedTypeProvider provider] ]];
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


static BOOL isPrimitiveNumericType(MPWTypeDefinition *type)
{
    switch ( type.objcTypeCode ) {
        case 'i': case 'I': case 's': case 'S':
        case 'l': case 'L': case 'q': case 'Q':
        case 'd': case 'f': case 'B':
            return YES;
        default:
            return NO;
    }
}

@implementation STHardcodedTypeProvider

+(instancetype)provider
{
    return [[[self alloc] init] autorelease];
}

-(MPWTypeDefinition*)returnTypeForSelector:(SEL)selector receiverType:(MPWTypeDefinition*)receiverType
{
    static NSSet *comparisons=nil;
    static NSSet *arithmetic=nil;
    static NSDictionary *extractors=nil;
    if ( !comparisons ) {
        // The mapped forms of  <  >  <=  >=  =  != , which all return BOOL.
        comparisons=[[NSSet alloc] initWithObjects:
            @"isLessThan:", @"isGreaterThan:", @"isLessThanOrEqualTo:",
            @"isGreaterThanOrEqualTo:", @"isEqual:", @"isNotEqualTo:", nil];
        // The mapped forms of  + - * /  ; result type follows the operand.
        arithmetic=[[NSSet alloc] initWithObjects:@"add:", @"sub:", @"mul:", @"div:", nil];
        // Selectors that conventionally yield a primitive on any object.
        extractors=[[NSDictionary alloc] initWithObjectsAndKeys:
            @"int", @"intValue", @"int", @"integerValue", @"long", @"longValue",
            @"float", @"floatValue", @"float", @"doubleValue", @"bool", @"boolValue",
            @"int", @"length", @"int", @"count", nil];
    }
    NSString *name=NSStringFromSelector(selector);
    if ( [comparisons containsObject:name] ) {
        return [MPWTypeDefinition descriptorForTypeName:@"bool"];
    }
    NSString *extractorType=extractors[name];
    if ( extractorType ) {
        return [MPWTypeDefinition descriptorForTypeName:extractorType];
    }
    if ( [arithmetic containsObject:name] && isPrimitiveNumericType(receiverType) ) {
        return receiverType;
    }
    return nil;
}

@end


@implementation STCompositeTypeProvider
{
    NSArray<id<STTypeProvider>> *_providers;
}

+(instancetype)providerWithProviders:(NSArray<id<STTypeProvider>>*)providers
{
    STCompositeTypeProvider *composite=[[[self alloc] init] autorelease];
    composite->_providers=[providers copy];
    return composite;
}

-(MPWTypeDefinition*)returnTypeForSelector:(SEL)selector receiverType:(MPWTypeDefinition*)receiverType
{
    for ( id<STTypeProvider> provider in _providers ) {
        MPWTypeDefinition *result=[provider returnTypeForSelector:selector receiverType:receiverType];
        if ( result ) {
            return result;
        }
    }
    return nil;
}

-(void)dealloc
{
    [_providers release];
    [super dealloc];
}

@end


@implementation NSObject (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return [MPWTypeDefinition idType];
}

@end


@implementation NSString (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return [MPWTypeDefinition descriptorForTypeName:@"NSString"];
}

@end


@implementation NSNumber (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return [MPWTypeDefinition descriptorForTypeName:@"NSNumber"];
}

@end


@implementation MPWLiteralExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    // A literal wraps its value; defer to the value's own type.
    return [self.theLiteral resultTypeIn:context];
}

@end


@implementation MPWMessageExpression (typeInference)

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    MPWTypeDefinition *receiverType=[self.receiver resultTypeIn:context];
    MPWTypeDefinition *result=[context.typeProvider returnTypeForSelector:self.selector receiverType:receiverType];
    return result ?: [MPWTypeDefinition idType];
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
