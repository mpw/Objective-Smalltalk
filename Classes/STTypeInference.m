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
#import "MPWBlockExpression.h"
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

static BOOL isObjectType(MPWTypeDefinition *type)
{
    return type.objcTypeCode == '@';
}

// The mapped forms of  <  >  <=  >=  =  != , which all yield BOOL.
static NSSet *comparisonSelectors(void)
{
    static NSSet *selectors=nil;
    if ( !selectors ) {
        selectors=[[NSSet alloc] initWithObjects:
            @"isLessThan:", @"isGreaterThan:", @"isLessThanOrEqualTo:",
            @"isGreaterThanOrEqualTo:", @"isEqual:", @"isNotEqualTo:", nil];
    }
    return selectors;
}

// The mapped forms of  + - * /  ; result type follows the operand.
static NSSet *arithmeticSelectors(void)
{
    static NSSet *selectors=nil;
    if ( !selectors ) {
        selectors=[[NSSet alloc] initWithObjects:@"add:", @"sub:", @"mul:", @"div:", nil];
    }
    return selectors;
}

@implementation STHardcodedTypeProvider

+(instancetype)provider
{
    return [[[self alloc] init] autorelease];
}

-(MPWTypeDefinition*)returnTypeForSelector:(SEL)selector receiverType:(MPWTypeDefinition*)receiverType
{
    static NSDictionary *extractors=nil;
    if ( !extractors ) {
        // Selectors that conventionally yield a primitive on any object.
        extractors=[[NSDictionary alloc] initWithObjectsAndKeys:
            @"int", @"intValue", @"int", @"integerValue", @"long", @"longValue",
            @"float", @"floatValue", @"float", @"doubleValue", @"bool", @"boolValue",
            @"int", @"length", @"int", @"count", nil];
    }
    NSString *name=NSStringFromSelector(selector);
    if ( [comparisonSelectors() containsObject:name] ) {
        return [MPWTypeDefinition descriptorForTypeName:@"bool"];
    }
    NSString *extractorType=extractors[name];
    if ( extractorType ) {
        return [MPWTypeDefinition descriptorForTypeName:extractorType];
    }
    if ( [arithmeticSelectors() containsObject:name] && isPrimitiveNumericType(receiverType) ) {
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


#pragma mark - coercion and early-bound-message nodes

@implementation STCoerce

+(instancetype)coerce:(STExpression*)expression from:(MPWTypeDefinition*)fromType to:(MPWTypeDefinition*)toType
{
    STCoerce *coerce=[[[self alloc] init] autorelease];
    coerce.expression=expression;
    coerce.fromType=fromType;
    coerce.toType=toType;
    return coerce;
}

+(STExpression*)coerceExpression:(STExpression*)expression to:(MPWTypeDefinition*)toType in:(STTypeContext*)context
{
    MPWTypeDefinition *fromType=[expression resultTypeIn:context];
    // Only object <-> primitive boundaries need a coercion; skip same-kind and
    // void targets.
    if ( toType && toType.objcTypeCode != 'v' && (isObjectType(fromType) != isObjectType(toType)) ) {
        return [self coerce:expression from:fromType to:toType];
    }
    return expression;
}

-(BOOL)isBoxing
{
    return !isObjectType(self.fromType) && isObjectType(self.toType);
}

-(BOOL)isUnboxing
{
    return isObjectType(self.fromType) && !isObjectType(self.toType);
}

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return self.toType;
}

-(id)evaluateIn:(id <STEvaluation>)context
{
    // The interpreter keeps everything boxed, so a coercion is a pass-through.
    return [self.expression evaluateIn:context];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%@→%@ %@>",[self class],self.fromType.name,self.toType.name,self.expression];
}

-(void)dealloc
{
    [_expression release];
    [_fromType release];
    [_toType release];
    [super dealloc];
}

@end


@implementation STPrimitiveMessageExpression

+(instancetype)fromMessage:(MPWMessageExpression*)message resultType:(MPWTypeDefinition*)resultType
{
    STPrimitiveMessageExpression *primitive=[[[self alloc] initWithReceiver:[message receiver]] autorelease];
    [primitive setSelector:[message selector]];
    [primitive setArgs:[message args]];
    primitive.primitiveResultType=resultType;
    return primitive;
}

-(MPWTypeDefinition*)resultTypeIn:(STTypeContext*)context
{
    return self.primitiveResultType ?: [MPWTypeDefinition idType];
}

-(id)typeAnnotateIn:(STTypeContext*)context
{
    return self;   // already resolved; receiver and args were annotated at creation
}

-(void)dealloc
{
    [_primitiveResultType release];
    [super dealloc];
}

@end


@implementation STCoerce (resultCoercion)

+(id)coerceResultOf:(id)body to:(MPWTypeDefinition*)toType in:(STTypeContext*)context
{
    if ( [body isKindOfClass:[MPWStatementList class]] ) {
        NSMutableArray *statements=[[[body statements] mutableCopy] autorelease];
        for ( NSInteger i=(NSInteger)statements.count-1; i>=0; i-- ) {
            if ( ![statements[i] isKindOfClass:[STVariableDefinition class]] ) {
                statements[i]=[self coerceExpression:statements[i] to:toType in:context];
                break;
            }
        }
        [body setStatements:statements];
        return body;
    } else if ( body ) {
        return [self coerceExpression:body to:toType in:context];
    }
    return body;
}

@end


#pragma mark - the annotation pass

@implementation NSObject (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    return self;   // leaf: literals, identifiers, blocks, bare values pass through
}

@end


@implementation MPWMessageExpression (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    id newReceiver=[self.receiver typeAnnotateIn:context];
    NSMutableArray *newArgs=[NSMutableArray arrayWithCapacity:[self.args count]];
    for ( id arg in self.args ) {
        [newArgs addObject:[arg typeAnnotateIn:context]];
    }
    [self setReceiver:newReceiver];
    [self setArgs:newArgs];

    NSString *selectorName=NSStringFromSelector(self.selector);
    BOOL isPrimitiveOperator=[comparisonSelectors() containsObject:selectorName] ||
                             [arithmeticSelectors() containsObject:selectorName];
    MPWTypeDefinition *receiverType=[newReceiver resultTypeIn:context];
    BOOL argsArePrimitive=YES;
    for ( id arg in newArgs ) {
        argsArePrimitive = argsArePrimitive && isPrimitiveNumericType([arg resultTypeIn:context]);
    }
    if ( isPrimitiveOperator && isPrimitiveNumericType(receiverType) && argsArePrimitive ) {
        MPWTypeDefinition *resultType=[context.typeProvider returnTypeForSelector:self.selector receiverType:receiverType];
        return [STPrimitiveMessageExpression fromMessage:self resultType:resultType];
    }
    // Late-bound send: a primitive receiver must be boxed to be messaged.
    if ( isPrimitiveNumericType(receiverType) ) {
        [self setReceiver:[STCoerce coerceExpression:newReceiver to:[MPWTypeDefinition idType] in:context]];
    }
    return self;
}

@end


@implementation MPWAssignmentExpression (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    self.rhs=[self.rhs typeAnnotateIn:context];
    if ( [self.lhs isKindOfClass:[STIdentifierExpression class]] ) {
        NSString *name=[[(STIdentifierExpression*)self.lhs identifier] identifierName];
        MPWTypeDefinition *lhsType=[context typeForName:name];
        if ( lhsType ) {
            self.rhs=[STCoerce coerceExpression:self.rhs to:lhsType in:context];
        }
    }
    return self;
}

@end


@implementation STVariableDefinition (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    if ( self.initializer ) {
        id annotated=[self.initializer typeAnnotateIn:context];
        self.initializer=[STCoerce coerceExpression:annotated to:(MPWTypeDefinition*)self.type in:context];
    }
    return self;
}

@end


@implementation MPWStatementList (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    NSMutableArray *newStatements=[NSMutableArray arrayWithCapacity:[[self statements] count]];
    for ( id statement in [self statements] ) {
        [newStatements addObject:[statement typeAnnotateIn:context]];
        // Later statements can see the types of earlier local definitions.
        if ( [statement isKindOfClass:[STVariableDefinition class]] ) {
            [context declareName:[statement name] type:[statement type]];
        }
    }
    [self setStatements:newStatements];
    return self;
}

@end


@implementation MPWBlockExpression (typeAnnotation)

-(id)typeAnnotateIn:(STTypeContext*)context
{
    // Blocks are generated as ^id(...), so the block's value is coerced to id.
    id body=[[self statements] typeAnnotateIn:context];
    body=[STCoerce coerceResultOf:body to:[MPWTypeDefinition idType] in:context];
    [self setStatements:body];
    return self;
}

@end
