//
//  MPWObjCGenerator.m
//  Arch-S
//
//  Created by Marcel Weiher on 15/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWObjCGenerator.h"
#import "MPWLiteralExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWBlockExpression.h"
#import "MPWCascadeExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWLiteralDictionaryExpression.h"
#import "MPWMessageExpression.h"
#import "MPWMethodHeader.h"
#import "MPWStatementList.h"
#import "STClassDefinition.h"
#import "STConnectionDefiner.h"
#import "STIdentifier.h"
#import "STIdentifierExpression.h"
#import "STScriptedMethod.h"
#import "STExpression.h"
#import "STSubscriptExpression.h"
#import "STTypeDescriptor.h"
#import "STVariableDefinition.h"
#import "STTypeInference.h"

@interface MPWObjCGenerator ()
// Names already declared in the method/block scope currently being generated,
// so a `var` definition for an already-hoisted local doesn't redeclare it.
@property (nonatomic, assign) NSMutableSet *declaredLocals;
// Instance variable names of the class currently being generated; these are
// members, not locals, so assignments to them must not be declared as locals.
@property (nonatomic, assign) NSSet *currentIvarNames;
// Types of the names in scope for the method currently being generated, so
// primitive locals can be declared with their C type.
@property (nonatomic, assign) STTypeContext *currentTypeContext;
-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type;
-(BOOL)isLocalScheme:(NSString*)scheme;
-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method;
-(NSString*)cOperatorForSelector:(NSString*)selector;
-(NSString*)unboxSelectorForType:(MPWTypeDefinition*)type;
@end

@implementation NSObject(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [self writeOnByteStream:aGenerator];
}


@end

@implementation MPWObjCGenerator

+defaultTarget
{
    return [NSMutableString string];
}

-(SEL)streamWriterMessage
{
    return @selector(generateObjectiveCOn:);
}

-(void)generateVariableWithName:aName
{
    [self writeString:aName];
}

-(void)generateIdentifier:(STIdentifier*)identifier
{
    NSString *scheme=[identifier schemeName];
    NSString *name=[identifier identifierName];
    if ( [name isEqual:@"true"] ) {
        [self writeString:@"@YES"];
    } else if ( [name isEqual:@"false"] ) {
        [self writeString:@"@NO"];
    } else if ( [name isEqual:@"nil"] ) {
        [self writeString:@"nil"];
    } else if ( scheme.length == 0 || [scheme isEqual:@"default"] ||
        [scheme isEqual:@"var"] || [scheme isEqual:@"class"] ||
        [scheme isEqual:@"self"] || [scheme isEqual:@"this"] ) {
        [self generateVariableWithName:name];
    } else {
        [self writeString:@"st_scheme_at("];
        [self writeNSString:scheme];
        [self writeString:@", "];
        [self writeNSString:name];
        [self writeString:@")"];
    }
}

-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type
{
    NSString *name=type.name ?: @"id";
    if ( type.objcTypeCode == '@' ) {
        if ( ![name isEqual:@"id"] && ![name hasSuffix:@"*"] ) {
            return [name stringByAppendingString:@" *"];
        }
        return name;
    }
    // Primitive: use the C spelling (int→long, bool→BOOL, float→double, …).
    return type.cName ?: name;
}

-(NSString*)cOperatorForSelector:(NSString*)selector
{
    static NSDictionary *operators=nil;
    if (!operators) {
        operators=[[NSDictionary alloc] initWithObjectsAndKeys:
            @"+", @"add:", @"-", @"sub:", @"*", @"mul:", @"/", @"div:",
            @"<", @"isLessThan:", @">", @"isGreaterThan:",
            @"<=", @"isLessThanOrEqualTo:", @">=", @"isGreaterThanOrEqualTo:",
            @"==", @"isEqual:", @"!=", @"isNotEqualTo:", nil];
    }
    return operators[selector];
}

-(NSString*)unboxSelectorForType:(MPWTypeDefinition*)type
{
    switch ( type.objcTypeCode ) {
        case 'B':                       return @"boolValue";
        case 'd': case 'f':             return @"doubleValue";
        case 'l': case 'q': case 'L': case 'Q':  return @"longValue";
        default:                        return @"intValue";
    }
}

-(NSString*)escapedObjectiveCString:(NSString*)source
{
    NSMutableString *escaped=[NSMutableString stringWithCapacity:source.length];
    for (NSUInteger i=0;i<source.length;i++) {
        unichar c=[source characterAtIndex:i];
        switch (c) {
            case '\\': [escaped appendString:@"\\\\"]; break;
            case '"':  [escaped appendString:@"\\\""]; break;
            case '\n': [escaped appendString:@"\\n"]; break;
            case '\r': [escaped appendString:@"\\r"]; break;
            case '\t': [escaped appendString:@"\\t"]; break;
            default: [escaped appendFormat:@"%C",c]; break;
        }
    }
    return escaped;
}

-(void)writeNSString:aString
{
    [self writeString:@"@\""];
    [self writeString:[self escapedObjectiveCString:aString]];
    [self writeString:@"\""];
}

-(void)writeKeyWord:aKeyWord andArg:arg
{
    [self writeString:@" "];
    [self writeString:aKeyWord];
    [self writeString:@":"];
    [self writeObject:arg];
}

-(void)writeMessage:selector toReceiver:receiver withArgs:args
{
    [self writeMessage:selector toReceiver:receiver withArgs:args superSend:NO];
}

-(void)writeMessage:selector toReceiver:receiver withArgs:args superSend:(BOOL)isSuperSend
{
    if ( [receiver isKindOfClass:[MPWBlockExpression class]] &&
         ([selector isEqual:@"value"] || [selector hasPrefix:@"value:"]) ) {
        [self writeString:@"("];
        [self writeObject:receiver];
        [self writeString:@")("];
        for (NSUInteger i=0;i<[args count];i++) {
            if (i) [self writeString:@", "];
            [self writeObject:args[i]];
        }
        [self writeString:@")"];
        return;
    }
    [self writeString:@"["];
    if ( isSuperSend ) {
        [self writeString:@"super"];
    } else {
        [self writeObject:receiver];
    }
    if ( [args count] == 0 ) {
        [self writeString:@" "];
        [self writeString:selector];
    } else {
        [[self do] writeKeyWord:[[selector componentsSeparatedByString:@":"] each] andArg:[args each]];
    }
    [self writeString:@"]"];
}

-(void)writeStatements:aList
{
    for (NSUInteger i=0;i<[aList count];i++) {
        if (i) [self writeString:@";\n"];
        [self writeObject:aList[i]];
    }
}

-(void)writeStatements:(NSArray*)aList returningLast:(BOOL)returnLast
{
    NSUInteger count=aList.count;
    for (NSUInteger i=0;i<count;i++) {
        BOOL lastReturns=returnLast && i == count-1 && ![aList[i] isKindOfClass:[STVariableDefinition class]];
        if ( lastReturns ) {
            [self writeString:@"return "];
        }
        [self writeObject:aList[i]];
        [self writeString:@";\n"];
        if ( returnLast && i == count-1 && !lastReturns ) {
            [self writeString:@"return nil;\n"];
        }
    }
    if ( returnLast && count == 0 ) {
        [self writeString:@"return nil;\n"];
    }
}

-(BOOL)isLocalScheme:(NSString*)scheme
{
    // The schemes the assignment generator emits as a plain C assignment,
    // excluding self/this (which denote instance variables, not locals).
    return scheme.length == 0 || [scheme isEqual:@"default"] || [scheme isEqual:@"var"];
}

-(NSSet*)localNamesWrittenIn:(NSSet*)writtenIdentifiers
{
    NSMutableSet *names=[NSMutableSet set];
    for (id ident in writtenIdentifiers) {
        if ( [ident respondsToSelector:@selector(schemeName)] &&
             [self isLocalScheme:[ident schemeName]] ) {
            [names addObject:[ident identifierName]];
        }
    }
    return names;
}

-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method
{
    STExpression *body=method.methodBody;
    NSMutableSet *locals=[[[self localNamesWrittenIn:[body variablesWritten]] mutableCopy] autorelease];
    [locals addObjectsFromArray:method.localVars];      // explicit `var` definitions

    MPWMethodHeader *header=method.header;
    for (int i=0;i<header.numArguments;i++) {
        [locals removeObject:[header argumentNameAtIndex:i]];
    }
    if ( self.currentIvarNames ) {
        [locals minusSet:self.currentIvarNames];
    }
    // Locals assigned inside a block must be __block so the mutation is shared
    // with the enclosing scope, matching the interpreter's flattened scoping.
    NSMutableSet *writtenInBlocks=[NSMutableSet set];
    for ( MPWBlockExpression *block in method.blocks ) {
        [writtenInBlocks unionSet:[self localNamesWrittenIn:[block variablesWritten]]];
        [locals removeObjectsInArray:block.arguments];  // block parameters are not locals
    }

    for ( NSString *name in [locals.allObjects sortedArrayUsingSelector:@selector(compare:)] ) {
        if ( [writtenInBlocks containsObject:name] ) {
            [self writeString:@"__block "];
        }
        // A declared primitive local gets its C type; everything else is id.
        MPWTypeDefinition *type=[self.currentTypeContext typeForName:name];
        NSString *cType=(type && type.objcTypeCode != '@') ? [self objectiveCTypeFor:type] : @"id";
        [self writeString:cType];
        [self writeString:@" "];
        [self writeString:name];
        [self writeString:@";\n"];
        [self.declaredLocals addObject:name];
    }
}

+testSelectors { return @[]; }

@end


@implementation NSString(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [aGenerator writeNSString:self];
}

@end

@implementation MPWLiteralExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [aGenerator writeObject:[self theLiteral]];
}

@end

@implementation NSNumber(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    if ( !strcmp(self.objCType, @encode(BOOL)) ) {
        [generator writeString:self.boolValue ? @"@YES" : @"@NO"];
    } else {
        [generator writeString:@"@("];
        [generator writeString:self.stringValue];
        [generator writeString:@")"];
    }
}

@end

@implementation MPWAssignmentExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    STIdentifier *identifier=[self.lhs isKindOfClass:[STIdentifierExpression class]]
        ? (STIdentifier*)[(STIdentifierExpression*)self.lhs identifier]
        : nil;
    NSString *scheme=[identifier schemeName];
    if ( scheme.length && ![scheme isEqual:@"default"] && ![scheme isEqual:@"var"] &&
        ![scheme isEqual:@"self"] && ![scheme isEqual:@"this"] ) {
        [generator writeString:@"st_scheme_at_put("];
        [generator writeNSString:scheme];
        [generator writeString:@", "];
        [generator writeNSString:[identifier identifierName]];
        [generator writeString:@", "];
        [generator writeObject:self.rhs];
        [generator writeString:@")"];
    } else {
        [generator writeObject:self.lhs];
        [generator writeString:@" = "];
        [generator writeObject:self.rhs];
    }
}

@end

@implementation MPWBlockExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    [generator writeString:@"^id("];
    NSArray *arguments=self.arguments;
    for (NSUInteger i=0;i<arguments.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeString:@"id "];
        [generator writeString:arguments[i]];
    }
    [generator writeString:@") {\n"];
    [generator writeStatements:self.statementArray returningLast:YES];
    [generator writeString:@"}"];
}

@end

@implementation MPWLiteralArrayExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    if (self.literalClassName) {
        [generator writeString:@"[[["];
        [generator writeString:self.literalClassName];
        [generator writeString:@" alloc] initWithArray:@["];
    } else {
        [generator writeString:@"@["];
    }
    for (NSUInteger i=0;i<self.objects.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:self.objects[i]];
    }
    [generator writeString:self.literalClassName ? @"]] autorelease]" : @"]"];
}

@end

@implementation MPWLiteralDictionaryExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    NSArray *keys=[self valueForKey:@"keys"];
    NSArray *values=[self valueForKey:@"values"];
    if (self.literalClassName) {
        [generator writeString:@"[[["];
        [generator writeString:self.literalClassName];
        [generator writeString:@" alloc] initWithDictionary:@{"];
    } else {
        [generator writeString:@"@{"];
    }
    NSUInteger count=MIN(keys.count, values.count);
    for (NSUInteger i=0;i<count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:keys[i]];
        [generator writeString:@": "];
        [generator writeObject:values[i]];
    }
    [generator writeString:self.literalClassName ? @"}] autorelease]" : @"}"];
}

@end

@implementation STSubscriptExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    [generator writeObject:self.receiver];
    [generator writeString:@"["];
    [generator writeObject:self.subscript];
    [generator writeString:@"]"];
}

@end

@implementation STConnectionDefiner(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    [generator writeString:@"st_connect_components("];
    [generator writeObject:self.lhs];
    [generator writeString:@", "];
    [generator writeObject:self.rhs];
    [generator writeString:@")"];
}

@end

@implementation MPWCascadeExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    NSArray *messages=[self valueForKey:@"messageExpressions"];
    [generator writeString:@"("];
    for (NSUInteger i=0;i<messages.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:messages[i]];
    }
    [generator writeString:@")"];
}

@end

@implementation STVariableDefinition(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    // When the enclosing method has already hoisted this local (so it can be
    // shared with blocks via __block), emit a plain assignment instead of a
    // second declaration.
    if ( [generator.declaredLocals containsObject:self.name] ) {
        [generator writeString:self.name];
    } else {
        [generator writeString:[generator objectiveCTypeFor:[self type]]];
        [generator writeString:@" "];
        [generator writeString:self.name];
        [generator.declaredLocals addObject:self.name];
    }
    if (self.initializer) {
        [generator writeString:@" = "];
        [generator writeObject:self.initializer];
    }
}

@end

@implementation STScriptedMethod(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    MPWMethodHeader *header=self.header;
    [generator writeString:@"- ("];
    [generator writeString:[generator objectiveCTypeFor:header.returnType]];
    [generator writeString:@")"];
    NSArray *selectorParts=[header.methodName componentsSeparatedByString:@":"];
    if (header.numArguments == 0) {
        [generator writeString:header.methodName];
    } else {
        for (int i=0;i<header.numArguments;i++) {
            if (i) [generator writeString:@" "];
            [generator writeString:selectorParts[i]];
            [generator writeString:@":("];
            [generator writeString:[generator objectiveCTypeFor:[header argumentTypeAtIndex:i]]];
            [generator writeString:@")"];
            [generator writeString:[header argumentNameAtIndex:i]];
        }
    }
    [generator writeString:@"\n{\n"];
    // Resolve early-bound primitive operations and insert box/unbox coercions,
    // including coercing the method's result to its declared return type.  The
    // pass is idempotent, so regenerating the same method is safe.
    STTypeContext *typeContext=[STTypeContext contextForMethod:self];
    id annotatedBody=[self.methodBody typeAnnotateIn:typeContext];
    if ( header.returnType.objcTypeCode != 'v' ) {
        annotatedBody=[STCoerce coerceResultOf:annotatedBody to:header.returnType in:typeContext];
    }
    [self setMethodBody:annotatedBody];
    STTypeContext *savedContext=generator.currentTypeContext;
    generator.currentTypeContext=typeContext;

    id body=self.methodBody;
    NSArray *statements=[body isKindOfClass:[MPWStatementList class]] ? [body statements] : @[ body ];
    NSMutableSet *savedLocals=generator.declaredLocals;
    generator.declaredLocals=[NSMutableSet set];
    [generator writeLocalDeclarationsForMethod:self];
    BOOL returnsValue=header.returnType.objcTypeCode != 'v';
    [generator writeStatements:statements returningLast:returnsValue];
    [generator writeString:@"}\n"];
    generator.declaredLocals=savedLocals;
    generator.currentTypeContext=savedContext;
}

@end

@implementation STClassDefinition(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    [generator writeString:@"@interface "];
    [generator writeString:self.name];
    [generator writeString:@" : "];
    [generator writeString:self.superclassNameToUse];
    NSArray *ivars=self.structureDefinition.fields;
    if (ivars.count) {
        [generator writeString:@" {\n"];
        for (id ivar in ivars) {
            NSString *type=[ivar respondsToSelector:@selector(typeName)] ? [ivar typeName] : @"id";
            [generator writeString:type ?: @"id"];
            [generator writeString:@" "];
            [generator writeString:[ivar name]];
            [generator writeString:@";\n"];
        }
        [generator writeString:@"}"];
    }
    [generator writeString:@"\n@end\n\n@implementation "];
    [generator writeString:self.name];
    [generator writeString:@"\n"];
    NSMutableSet *ivarNames=[NSMutableSet set];
    for (id ivar in ivars) {
        [ivarNames addObject:[ivar name]];
    }
    NSSet *savedIvarNames=generator.currentIvarNames;
    generator.currentIvarNames=ivarNames;
    for (STScriptedMethod *method in self.methods) {
        [generator writeObject:method];
    }
    generator.currentIvarNames=savedIvarNames;
    for (STScriptedMethod *method in self.classMethods) {
        NSMutableString *methodCode=[NSMutableString stringWithString:[MPWObjCGenerator process:method]];
        if ([methodCode hasPrefix:@"-"]) [methodCode replaceCharactersInRange:NSMakeRange(0, 1) withString:@"+"];
        [generator writeString:methodCode];
    }
    [generator writeString:@"@end\n"];
}

@end


@implementation STPrimitiveMessageExpression(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    NSString *cOperator=[generator cOperatorForSelector:NSStringFromSelector(self.selector)];
    if ( cOperator && self.args.count == 1 ) {
        [generator writeString:@"("];
        [generator writeObject:self.receiver];
        [generator writeString:@" "];
        [generator writeString:cOperator];
        [generator writeString:@" "];
        [generator writeObject:self.args[0]];
        [generator writeString:@")"];
    } else {
        // Not a lowered binary operator; fall back to a normal message send.
        [generator writeMessage:NSStringFromSelector(self.selector) toReceiver:self.receiver withArgs:self.args];
    }
}

@end


@implementation STCoerce(generateObjectiveCOn)

-(void)generateObjectiveCOn:(MPWObjCGenerator*)generator
{
    if ( [self isBoxing] ) {
        [generator writeString:@"@("];
        [generator writeObject:self.expression];
        [generator writeString:@")"];
    } else if ( [self isUnboxing] ) {
        [generator writeString:@"["];
        [generator writeObject:self.expression];
        [generator writeString:@" "];
        [generator writeString:[generator unboxSelectorForType:self.toType]];
        [generator writeString:@"]"];
    } else {
        [generator writeObject:self.expression];
    }
}

@end
