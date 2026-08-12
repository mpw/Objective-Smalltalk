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
#import <MPWFoundation/MPWStringTemplate.h>

// Interpolatable "..." strings are MPWStringLiteral with hasSingleQuotes == NO.
@interface NSObject(hasSingleQuotes)
-(BOOL)hasSingleQuotes;
@end

@interface MPWObjCGenerator ()
// Names already declared in the method/block scope currently being generated,
// so a `var` definition for an already-hoisted local doesn't redeclare it.
@property (nonatomic, assign) NSMutableSet *declaredLocals;
// Instance variables (name → type) of the class currently being generated:
// members, not locals, so they aren't declared as locals, and `this:` accesses
// them with their declared type.
@property (nonatomic, assign) NSDictionary *currentIvarTypes;
// Types of the names in scope for the method currently being generated, so
// primitive locals can be declared with their C type.
@property (nonatomic, assign) STTypeContext *currentTypeContext;
-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type;
-(BOOL)isLocalScheme:(NSString*)scheme;
-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method;
-(NSString*)cOperatorForSelector:(NSString*)selector;
-(NSString*)unboxSelectorForType:(MPWTypeDefinition*)type;
-(void)writeAccessorForName:(NSString*)name type:(MPWTypeDefinition*)type;
-(BOOL)isLowerableControlStructure:statement;
-(void)writeControlStructure:(MPWMessageExpression*)message;
-(void)writePrimitiveOperand:operand;
-(void)writeInterpolatedString:(NSString*)string;
-(void)writeStaticInterpolation:(NSArray*)fragments placeholders:(NSArray*)placeholders;
-(void)writeWrappedInterpolation:(NSString*)string placeholders:(NSArray*)placeholders;
-(BOOL)placeholderIsBareName:(id)identifier;
-(BOOL)placeholderIsStatic:(id)identifier;
@end

@implementation NSObject(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [self writeOnByteStream:aGenerator];
}


@end

@implementation MPWObjCGenerator

// +defaultTarget and +transpile: are inherited from MPWLanguageGenerator.
-(SEL)streamWriterMessage
{
    return @selector(generateObjectiveCOn:);
}

-(void)generateVariableWithName:aName
{
    [self writeString:aName];
}

-(void)writeIdentifierWithScheme:(NSString*)scheme name:(NSString*)name
{
    if ( [name isEqual:@"true"] ) {
        [self writeString:@"@YES"];
    } else if ( [name isEqual:@"false"] ) {
        [self writeString:@"@NO"];
    } else if ( [name isEqual:@"nil"] ) {
        [self writeString:@"nil"];
    } else if ( [name isEqual:@"stdout"] ) {
        [self writeString:@"[MPWByteStream Stdout]"];
    } else if ( [scheme isEqual:@"this"] ) {
        // this:hi resolves to the property/instance variable via its getter.
        [self writeString:@"[self "];
        [self writeString:name];
        [self writeString:@"]"];
    } else if ( scheme.length == 0 || [scheme isEqual:@"default"] ||
        [scheme isEqual:@"var"] || [scheme isEqual:@"class"] ||
        [scheme isEqual:@"self"] ) {
        [self generateVariableWithName:name];
    } else {
        [self writeString:@"st_scheme_at("];
        [self writeNSString:scheme];
        [self writeString:@", "];
        [self writeNSString:name];
        [self writeString:@")"];
    }
}

-(void)generateIdentifier:(STIdentifier*)identifier
{
    [self writeIdentifierWithScheme:[identifier schemeName] name:[identifier identifierName]];
}

-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type
{
    // cName is the Objective-C spelling: primitives (int→long, bool→BOOL),
    // object classes with a trailing asterisk (NSString*), "id" for id and for
    // semantic/MDA object types (Text, EmailAddress, …) that have no mapped
    // Objective-C class.
    return type.cName ?: @"id";
}

+(NSString*)standardImports
{
    return @"#import <Foundation/Foundation.h>\n"
            "#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>\n\n";
}

-(void)writeAccessorForName:(NSString*)name type:(MPWTypeDefinition*)type
{
    NSString *setterName=[NSString stringWithFormat:@"set%@%@",
        [[name substringToIndex:1] uppercaseString], [name substringFromIndex:1]];
    NSString *cType=type ? [self objectiveCTypeFor:type] : @"id";
    if ( !type || type.objcTypeCode == '@' ) {
        if ( [cType isEqual:@"id"] ) {
            [self writeString:[NSString stringWithFormat:@"idAccessor( %@, %@ )\n",name,setterName]];
        } else {
            [self writeString:[NSString stringWithFormat:@"objectAccessor( %@, %@, %@ )\n",cType,name,setterName]];
        }
    } else {
        [self writeString:[NSString stringWithFormat:@"scalarAccessor( %@, %@, %@ )\n",cType,name,setterName]];
    }
}

-(void)writePrimitiveOperand:operand
{
    // Inside a lowered primitive operation a numeric literal is a raw C number,
    // not a boxed @(n).
    id literal=[operand isKindOfClass:[MPWLiteralExpression class]] ? [operand theLiteral] : operand;
    if ( [literal isKindOfClass:[NSNumber class]] ) {
        [self writeString:[literal stringValue]];
    } else {
        [self writeObject:operand];
    }
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

// Writes a placeholder value for a stringWithFormat %@ slot: the bare identifier,
// boxed when it is a primitive so it fits the object format.
-(void)writeInterpolationPlaceholder:identifier
{
    MPWTypeDefinition *type=[self.currentTypeContext typeForName:[identifier identifierName]];
    BOOL isPrimitive=type && type.objcTypeCode != '@' && type.objcTypeCode != 'v';
    if ( isPrimitive ) [self writeString:@"@("];
    [self generateIdentifier:identifier];
    if ( isPrimitive ) [self writeString:@")"];
}

// A bare name — no scheme (this:), no path (a/b, a.b).  Bare names can be emitted
// as a plain C reference; scheme-qualified / path placeholders can't.
-(BOOL)placeholderIsBareName:(id)identifier
{
    NSString *path=[identifier identifierName];
    return [path rangeOfString:@":"].location == NSNotFound
        && [path rangeOfString:@"/"].location == NSNotFound
        && [path rangeOfString:@"."].location == NSNotFound;
}

// Static (stringWithFormat) resolution is only valid when every placeholder is a
// bare name that is a local/argument — not an instance variable, whose value the
// interpreter reaches through the environment, and not a scheme/path placeholder.
-(BOOL)placeholderIsStatic:(id)identifier
{
    return [self placeholderIsBareName:identifier]
        && !self.currentIvarTypes[[identifier identifierName]];
}

// A "..." string with {placeholder}s.  When all placeholders are simple locals we
// emit a plain [NSString stringWithFormat:…]; otherwise we defer to the runtime,
// mirroring the interpreter, so scheme-qualified paths (this:name) and the fuller
// interpolation grammar resolve exactly as they do when interpreted.
-(void)writeInterpolatedString:(NSString*)string
{
    NSArray *fragments=[MPWStringTemplate parseString:string];
    NSMutableArray *placeholders=[NSMutableArray array];
    for (id fragment in fragments) {
        if ( ![fragment isKindOfClass:[NSString class]] ) {
            [placeholders addObject:fragment];   // an MPWGenericIdentifier
        }
    }
    BOOL allStatic=YES;
    for (id placeholder in placeholders) {
        if ( ![self placeholderIsStatic:placeholder] ) { allStatic=NO; break; }
    }
    if ( allStatic ) {
        [self writeStaticInterpolation:fragments placeholders:placeholders];
    } else {
        [self writeWrappedInterpolation:string placeholders:placeholders];
    }
}

-(void)writeStaticInterpolation:(NSArray*)fragments placeholders:(NSArray*)placeholders
{
    NSMutableString *format=[NSMutableString string];
    for (id fragment in fragments) {
        if ( [fragment isKindOfClass:[NSString class]] ) {
            // A literal % must be doubled for the format string.
            [format appendString:[fragment stringByReplacingOccurrencesOfString:@"%" withString:@"%%"]];
        } else {
            [format appendString:@"%@"];
        }
    }
    if ( placeholders.count == 0 ) {
        [self writeNSString:format];    // no placeholders: an ordinary string
        return;
    }
    [self writeString:@"[NSString stringWithFormat:"];
    [self writeNSString:format];
    for (id placeholder in placeholders) {
        [self writeString:@", "];
        [self writeInterpolationPlaceholder:placeholder];
    }
    [self writeString:@"]"];
}

-(void)writeWrappedInterpolation:(NSString*)string placeholders:(NSArray*)placeholders
{
    // self resolves scheme-qualified paths ({this:name}); bare names are handed to
    // the environment as bound locals (a bare ivar is emitted as its own field).
    [self writeString:@"[STEvaluator interpolate:"];
    [self writeNSString:string];
    [self writeString:@" forObject:self locals:@{"];
    BOOL first=YES;
    NSMutableSet *bound=[NSMutableSet set];
    for (id placeholder in placeholders) {
        if ( ![self placeholderIsBareName:placeholder] ) continue;   // self handles it
        NSString *name=[placeholder identifierName];
        if ( [bound containsObject:name] ) continue;
        [bound addObject:name];
        if ( !first ) [self writeString:@", "];
        first=NO;
        [self writeNSString:name];   // writeNSString: already emits the @"…" literal
        [self writeString:@": "];
        [self writeInterpolationPlaceholder:placeholder];
    }
    [self writeString:@"}]"];
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

-(BOOL)isBlock:node { return [node isKindOfClass:[MPWBlockExpression class]]; }

// A control-structure message (ifTrue:/whileTrue:/to:do:/do:) with block arms,
// lowerable to a native C control structure when its value is not needed.
-(BOOL)isLowerableControlStructure:statement
{
    if ( ![statement isKindOfClass:[MPWMessageExpression class]] ) {
        return NO;
    }
    NSString *selector=NSStringFromSelector([statement selector]);
    NSArray *args=[statement args];
    id receiver=[statement receiver];
    if ( [selector isEqual:@"ifTrue:"] || [selector isEqual:@"ifTrue:ifFalse:"] ) {
        for (id arg in args) { if ( ![self isBlock:arg] ) return NO; }
        return YES;
    }
    if ( [selector isEqual:@"whileTrue:"] ) {
        // { cond } whileTrue:{ body } — cond must be a single-statement block.
        return [self isBlock:receiver] && args.count == 1 && [self isBlock:args[0]] &&
               [[receiver statementArray] count] == 1;
    }
    if ( [selector isEqual:@"to:do:"] ) {
        return args.count == 2 && [self isBlock:args[1]] && [[args[1] arguments] count] == 1;
    }
    if ( [selector isEqual:@"do:"] ) {
        return args.count == 1 && [self isBlock:args[0]] && [[args[0] arguments] count] == 1;
    }
    return NO;
}

// Emit a C boolean expression from an Objective-Smalltalk condition, unwrapping
// the box the annotator added so a primitive comparison stays raw.
-(void)writeCCondition:condition
{
    if ( [condition isKindOfClass:[STCoerce class]] && [(STCoerce*)condition isBoxing] ) {
        [self writeObject:[(STCoerce*)condition expression]];
    } else {
        [self writeString:@"["];
        [self writeObject:condition];
        [self writeString:@" boolValue]"];
    }
}

// Emit a loop bound as a raw C long: a numeric literal verbatim, a primitive as
// itself, an object unboxed with -longValue.
-(void)writeLoopBound:bound
{
    // The arg-coercion pass boxes the bound because to:do: takes objects; for a
    // C loop counter we want the raw primitive back.
    if ( [bound isKindOfClass:[STCoerce class]] && [(STCoerce*)bound isBoxing] ) {
        bound=[(STCoerce*)bound expression];
    }
    id literal=[bound isKindOfClass:[MPWLiteralExpression class]] ? [bound theLiteral] : bound;
    if ( [literal isKindOfClass:[NSNumber class]] ) {
        [self writeString:[literal stringValue]];
        return;
    }
    MPWTypeDefinition *type=[bound resultTypeIn:self.currentTypeContext];
    if ( type.objcTypeCode != '@' && type.objcTypeCode != 'v' ) {
        [self writeObject:bound];
    } else {
        [self writeString:@"["];
        [self writeObject:bound];
        [self writeString:@" longValue]"];
    }
}

-(void)writeConditionalStatement:(MPWMessageExpression*)conditional
{
    [self writeString:@"if ( "];
    [self writeCCondition:[conditional receiver]];
    [self writeString:@" ) {\n"];
    [self writeStatements:[[conditional args][0] statementArray] returningLast:NO];
    [self writeString:@"}"];
    if ( [conditional args].count >= 2 ) {
        [self writeString:@" else {\n"];
        [self writeStatements:[[conditional args][1] statementArray] returningLast:NO];
        [self writeString:@"}"];
    }
    [self writeString:@"\n"];
}

-(void)writeWhileStatement:(MPWMessageExpression*)whileMessage
{
    [self writeString:@"while ( "];
    [self writeCCondition:[[whileMessage receiver] statementArray][0]];
    [self writeString:@" ) {\n"];
    [self writeStatements:[[whileMessage args][0] statementArray] returningLast:NO];
    [self writeString:@"}\n"];
}

-(void)writeForStatement:(MPWMessageExpression*)forMessage
{
    MPWBlockExpression *body=[forMessage args][1];
    NSString *loopVar=[body arguments][0];
    // for ( long i = start; i <= end; i++ ) { … }  — the loop variable is a
    // plain primitive integer; the annotator boxes it where the body needs an object.
    [self writeString:@"for ( long "];
    [self writeString:loopVar];
    [self writeString:@" = "];
    [self writeLoopBound:[forMessage receiver]];
    [self writeString:@"; "];
    [self writeString:loopVar];
    [self writeString:@" <= "];
    [self writeLoopBound:[forMessage args][0]];
    [self writeString:@"; "];
    [self writeString:loopVar];
    [self writeString:@"++ ) {\n"];
    [self writeStatements:[body statementArray] returningLast:NO];
    [self writeString:@"}\n"];
}

-(void)writeForeachStatement:(MPWMessageExpression*)doMessage
{
    MPWBlockExpression *body=[doMessage args][0];
    [self writeString:@"for ( id "];
    [self writeString:[body arguments][0]];
    [self writeString:@" in "];
    [self writeObject:[doMessage receiver]];
    [self writeString:@" ) {\n"];
    [self writeStatements:[body statementArray] returningLast:NO];
    [self writeString:@"}\n"];
}

-(void)writeControlStructure:(MPWMessageExpression*)message
{
    NSString *selector=NSStringFromSelector([message selector]);
    if ( [selector isEqual:@"whileTrue:"] ) {
        [self writeWhileStatement:message];
    } else if ( [selector isEqual:@"to:do:"] ) {
        [self writeForStatement:message];
    } else if ( [selector isEqual:@"do:"] ) {
        [self writeForeachStatement:message];
    } else {
        [self writeConditionalStatement:message];
    }
}

-(void)writeStatements:(NSArray*)aList returningLast:(BOOL)returnLast
{
    NSUInteger count=aList.count;
    for (NSUInteger i=0;i<count;i++) {
        BOOL lastReturns=returnLast && i == count-1 && ![aList[i] isKindOfClass:[STVariableDefinition class]];
        // Lower control-structure sends to native C control flow, but only where
        // the value is discarded — a returned one keeps its expression form.
        if ( !lastReturns && [self isLowerableControlStructure:aList[i]] ) {
            [self writeControlStructure:aList[i]];
        } else {
            id statement=aList[i];
            if ( lastReturns ) {
                [self writeString:@"return "];
            } else if ( [statement isKindOfClass:[STCoerce class]] ) {
                // The value is discarded, so a box/unbox coercion of it is pointless.
                statement=[(STCoerce*)statement expression];
            }
            [self writeObject:statement];
            [self writeString:@";\n"];
        }
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
    if ( self.currentIvarTypes ) {
        [locals minusSet:[NSSet setWithArray:self.currentIvarTypes.allKeys]];
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
    id literal=[self theLiteral];
    // A double-quoted "..." string interpolates its {placeholder}s.
    if ( [literal respondsToSelector:@selector(hasSingleQuotes)] && ![literal hasSingleQuotes] ) {
        [aGenerator writeInterpolatedString:literal];
    } else {
        [aGenerator writeObject:literal];
    }
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
    if ( [scheme isEqual:@"this"] ) {
        // this:hi := rhs  →  [self setHi:rhs]
        NSString *name=[identifier identifierName];
        [generator writeString:@"[self set"];
        [generator writeString:[[name substringToIndex:1] uppercaseString]];
        [generator writeString:[name substringFromIndex:1]];
        [generator writeString:@":"];
        [generator writeObject:self.rhs];
        [generator writeString:@"]"];
    } else if ( scheme.length && ![scheme isEqual:@"default"] && ![scheme isEqual:@"var"] &&
        ![scheme isEqual:@"self"] ) {
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
    // Instance variables are in scope with their declared types (this:age → int),
    // but a same-named argument or local shadows them.
    for (NSString *ivarName in generator.currentIvarTypes) {
        if ( ![typeContext typeForName:ivarName] ) {
            [typeContext declareName:ivarName type:generator.currentIvarTypes[ivarName]];
        }
    }
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
            MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
            [generator writeString:ivarType ? [generator objectiveCTypeFor:ivarType] : @"id"];
            [generator writeString:@" "];
            [generator writeString:[ivar name]];
            [generator writeString:@";\n"];
        }
        [generator writeString:@"}"];
    }
    [generator writeString:@"\n@end\n\n@implementation "];
    [generator writeString:self.name];
    [generator writeString:@"\n"];
    // Give each instance variable accessors so it is reachable as a property.
    for (id ivar in ivars) {
        MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
        [generator writeAccessorForName:[ivar name] type:ivarType];
    }
    NSMutableDictionary *ivarTypes=[NSMutableDictionary dictionary];
    for (id ivar in ivars) {
        MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
        ivarTypes[[ivar name]]=ivarType ?: [MPWTypeDefinition idType];
    }
    NSDictionary *savedIvarTypes=generator.currentIvarTypes;
    generator.currentIvarTypes=ivarTypes;
    for (STScriptedMethod *method in self.methods) {
        [generator writeObject:method];
    }
    generator.currentIvarTypes=savedIvarTypes;
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
        [generator writePrimitiveOperand:self.receiver];
        [generator writeString:@" "];
        [generator writeString:cOperator];
        [generator writeString:@" "];
        [generator writePrimitiveOperand:self.args[0]];
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
    id literal=[self.expression isKindOfClass:[MPWLiteralExpression class]] ? [self.expression theLiteral] : nil;
    if ( [self isBoxing] ) {
        [generator writeString:@"@("];
        [generator writeObject:self.expression];
        [generator writeString:@")"];
    } else if ( [self isUnboxing] && [literal isKindOfClass:[NSNumber class]] ) {
        // Unboxing a numeric literal is just the raw C number.
        [generator writeString:[literal stringValue]];
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
