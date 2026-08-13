//
//  MPWLanguageGenerator.m
//  ObjectiveSmalltalk
//
//  The Objective-C-family source generator: it owns the single tree-walk AND the
//  shared source emission (bracket message sends, @implementation, method headers,
//  control-structure lowering, type inference).  Objective-C and Objective-J differ
//  only in a few leaves — the class-name mapping (NS↔CP), the import directive, and
//  a handful of syntactic details — which subclasses override.
//

#import "MPWLanguageGenerator.h"
#import "STCompiler.h"
#import "STTypeInference.h"
#import "STTypeDescriptor.h"
#import "MPWMethodHeader.h"
#import "STScriptedMethod.h"
#import "STClassDefinition.h"
#import "MPWStatementList.h"
#import "STVariableDefinition.h"
#import "MPWBlockExpression.h"
#import "MPWMessageExpression.h"
#import "MPWLiteralExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWLiteralDictionaryExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWCascadeExpression.h"
#import "STIdentifierExpression.h"
#import "STIdentifier.h"
#import "STSubscriptExpression.h"
#import "STConnectionDefiner.h"
#import <MPWFoundation/MPWStringTemplate.h>

// Double-quoted "..." string literals carry hasSingleQuotes == NO and interpolate.
@interface NSObject(hasSingleQuotes)
-(BOOL)hasSingleQuotes;
@end

@interface MPWLanguageGenerator ()
// Names already declared in the method/block scope currently being generated, so a
// `var` definition for an already-hoisted local doesn't redeclare it.
@property (nonatomic, assign) NSMutableSet *declaredLocals;
-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type;
-(void)writeAccessorForName:(NSString*)name type:(MPWTypeDefinition*)type;
-(NSString*)unboxSelectorForType:(MPWTypeDefinition*)type;
-(NSString*)cOperatorForSelector:(NSString*)selector;
-(void)writePrimitiveOperand:operand;
-(NSString*)escapedString:(NSString*)source;
-(void)writeQuotedString:aString;
-(void)writeInterpolationPlaceholder:identifier;
-(BOOL)placeholderIsBareName:(id)identifier;
-(BOOL)placeholderIsStatic:(id)identifier;
-(void)writeInterpolatedString:(NSString*)string;
-(void)writeStaticInterpolation:(NSArray*)fragments placeholders:(NSArray*)placeholders;
-(void)writeWrappedInterpolation:(NSString*)string placeholders:(NSArray*)placeholders;
-(void)writeKeyWord:aKeyWord andArg:arg;
-(void)generateVariableWithName:aName;
-(void)writeIdentifierWithScheme:(NSString*)scheme name:(NSString*)name;
-(void)generateIdentifier:(STIdentifier*)identifier;
-(BOOL)isLocalScheme:(NSString*)scheme;
-(NSSet*)localNamesWrittenIn:(NSSet*)writtenIdentifiers;
-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method;
-(BOOL)isBlock:node;
-(void)writeConditionalStatement:(MPWMessageExpression*)conditional;
-(void)writeWhileStatement:(MPWMessageExpression*)whileMessage;
-(void)writeForStatement:(MPWMessageExpression*)forMessage;
@end

@implementation MPWLanguageGenerator

+defaultTarget
{
    return [NSMutableString string];
}

// Not a test class itself — don't inherit MPWByteStream's tests, which assume its
// data target rather than our string target.
+testSelectors { return @[]; }

+(NSString*)transpile:(NSString*)source
{
    NSMutableString *result=[NSMutableString string];
    MPWLanguageGenerator *generator=[self streamWithTarget:result];
    [generator writeObject:[[STCompiler compiler] compile:source]];
    return result;
}

-(SEL)streamWriterMessage { return @selector(generateCodeOn:); }

-(BOOL)isInstanceVariableName:(NSString*)name
{
    return self.currentIvarTypes[name] != nil;
}

// Map an Objective-C class name to the target dialect's spelling.  Identity for
// Objective-C; Objective-J swaps the NS* prefix for CP*.
-(NSString*)mapClassName:(NSString*)className { return className; }

-(void)subclassResponsibility:(SEL)cmd
{
    [NSException raise:@"subclassResponsibility"
                format:@"%@ is an emit primitive that %@ must override",
                       NSStringFromSelector(cmd), [self class]];
}

#pragma mark - shared traversal skeleton

-(BOOL)isBlock:node { return [node isKindOfClass:[MPWBlockExpression class]]; }

// A control-structure message (ifTrue:/whileTrue:/to:do:/do:) with block arms,
// lowerable to a native control structure when its value is not needed.
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

-(void)writeConditionalStatement:(MPWMessageExpression*)conditional
{
    [self writeString:@"if ( "];
    [self emitBooleanCondition:[conditional receiver]];
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
    [self emitBooleanCondition:[[whileMessage receiver] statementArray][0]];
    [self writeString:@" ) {\n"];
    [self writeStatements:[[whileMessage args][0] statementArray] returningLast:NO];
    [self writeString:@"}\n"];
}

-(void)writeForStatement:(MPWMessageExpression*)forMessage
{
    MPWBlockExpression *body=[forMessage args][1];
    NSString *loopVar=[body arguments][0];
    [self writeString:@"for ( "];
    [self writeString:[self loopVariableDeclaration]];
    [self writeString:loopVar];
    [self writeString:@" = "];
    [self emitLoopBound:[forMessage receiver]];
    [self writeString:@"; "];
    [self writeString:loopVar];
    [self writeString:@" <= "];
    [self emitLoopBound:[forMessage args][0]];
    [self writeString:@"; "];
    [self writeString:loopVar];
    [self writeString:@"++ ) {\n"];
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
        [self emitForeachStatement:message];
    } else {
        [self writeConditionalStatement:message];
    }
}

-(void)writeStatementList:(NSArray*)aList
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
        // Lower control-structure sends to native control flow, but only where the
        // value is discarded — a returned one keeps its expression (message) form.
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
            [self writeString:@"return "];
            [self writeString:[self nullLiteral]];
            [self writeString:@";\n"];
        }
    }
    if ( returnLast && count == 0 ) {
        [self writeString:@"return "];
        [self writeString:[self nullLiteral]];
        [self writeString:@";\n"];
    }
}

#pragma mark - identifiers

-(void)generateVariableWithName:aName
{
    [self writeString:aName];
}

-(void)writeIdentifierWithScheme:(NSString*)scheme name:(NSString*)name
{
    if ( [name isEqual:@"true"] ) {
        [self emitBooleanLiteral:YES];
    } else if ( [name isEqual:@"false"] ) {
        [self emitBooleanLiteral:NO];
    } else if ( [name isEqual:@"nil"] ) {
        [self emitNilLiteral];
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
        [self writeQuotedString:scheme];
        [self writeString:@", "];
        [self writeQuotedString:name];
        [self writeString:@")"];
    }
}

-(void)generateIdentifier:(STIdentifier*)identifier
{
    [self writeIdentifierWithScheme:[identifier schemeName] name:[identifier identifierName]];
}

-(void)emitIdentifier:(STIdentifier*)identifier { [self generateIdentifier:identifier]; }

#pragma mark - types and accessors

-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type
{
    // cName is the Objective-C spelling: primitives (int→long, bool→BOOL), object
    // classes with a trailing asterisk (NSString*), "id" for id and for
    // semantic/MDA object types with no mapped class.  Object class names are run
    // through the dialect mapping (NS→CP for Objective-J).
    NSString *cName=type.cName ?: @"id";
    if ( [cName hasSuffix:@"*"] ) {
        return [[self mapClassName:[cName substringToIndex:cName.length-1]] stringByAppendingString:@"*"];
    }
    return cName;
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

-(NSString*)unboxSelectorForType:(MPWTypeDefinition*)type
{
    switch ( type.objcTypeCode ) {
        case 'B':                       return @"boolValue";
        case 'd': case 'f':             return @"doubleValue";
        case 'l': case 'q': case 'L': case 'Q':  return @"longValue";
        default:                        return @"intValue";
    }
}

#pragma mark - primitive-operator lowering (identical in C and JavaScript)

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

-(void)writePrimitiveOperand:operand
{
    id literal=[operand isKindOfClass:[MPWLiteralExpression class]] ? [operand theLiteral] : operand;
    if ( [literal isKindOfClass:[NSNumber class]] ) {
        [self writeString:[literal stringValue]];
    } else {
        [self writeObject:operand];
    }
}

-(void)emitPrimitiveMessage:(STPrimitiveMessageExpression*)message
{
    NSString *cOperator=[self cOperatorForSelector:NSStringFromSelector([(id)message selector])];
    if ( cOperator && [(id)message args].count == 1 ) {
        [self writeString:@"("];
        [self writePrimitiveOperand:[(id)message receiver]];
        [self writeString:@" "];
        [self writeString:cOperator];
        [self writeString:@" "];
        [self writePrimitiveOperand:[(id)message args][0]];
        [self writeString:@")"];
    } else {
        [self emitMessageSelector:NSStringFromSelector([(id)message selector])
                         receiver:[(id)message receiver] args:[(id)message args] super:NO];
    }
}

-(void)emitCoerce:(STCoerce*)coercion
{
    id literal=[coercion.expression isKindOfClass:[MPWLiteralExpression class]] ? [coercion.expression theLiteral] : nil;
    if ( [coercion isBoxing] ) {
        [self writeString:@"@("];
        [self writeObject:coercion.expression];
        [self writeString:@")"];
    } else if ( [coercion isUnboxing] && [literal isKindOfClass:[NSNumber class]] ) {
        [self writeString:[literal stringValue]];
    } else if ( [coercion isUnboxing] ) {
        [self writeString:@"["];
        [self writeObject:coercion.expression];
        [self writeString:@" "];
        [self writeString:[self unboxSelectorForType:coercion.toType]];
        [self writeString:@"]"];
    } else {
        [self writeObject:coercion.expression];
    }
}

#pragma mark - string literals

-(NSString*)escapedString:(NSString*)source
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

// An @"…" object-string literal (the same in Objective-C and Objective-J).
-(void)writeQuotedString:aString
{
    [self writeString:@"@\""];
    [self writeString:[self escapedString:aString]];
    [self writeString:@"\""];
}

#pragma mark - string interpolation

-(void)writeInterpolationPlaceholder:identifier
{
    MPWTypeDefinition *type=[self.currentTypeContext typeForName:[identifier identifierName]];
    BOOL isPrimitive=type && type.objcTypeCode != '@' && type.objcTypeCode != 'v';
    if ( isPrimitive ) [self writeString:@"@("];
    [self generateIdentifier:identifier];
    if ( isPrimitive ) [self writeString:@")"];
}

-(BOOL)placeholderIsBareName:(id)identifier
{
    NSString *path=[identifier identifierName];
    return [path rangeOfString:@":"].location == NSNotFound
        && [path rangeOfString:@"/"].location == NSNotFound
        && [path rangeOfString:@"."].location == NSNotFound;
}

-(BOOL)placeholderIsStatic:(id)identifier
{
    return [self placeholderIsBareName:identifier]
        && !self.currentIvarTypes[[identifier identifierName]];
}

-(void)writeInterpolatedString:(NSString*)string
{
    NSArray *fragments=[MPWStringTemplate parseString:string];
    NSMutableArray *placeholders=[NSMutableArray array];
    for (id fragment in fragments) {
        if ( ![fragment isKindOfClass:[NSString class]] ) {
            [placeholders addObject:fragment];
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
            [format appendString:[fragment stringByReplacingOccurrencesOfString:@"%" withString:@"%%"]];
        } else {
            [format appendString:@"%@"];
        }
    }
    if ( placeholders.count == 0 ) {
        [self writeQuotedString:format];
        return;
    }
    [self writeString:@"[NSString stringWithFormat:"];
    [self writeQuotedString:format];
    for (id placeholder in placeholders) {
        [self writeString:@", "];
        [self writeInterpolationPlaceholder:placeholder];
    }
    [self writeString:@"]"];
}

-(void)writeWrappedInterpolation:(NSString*)string placeholders:(NSArray*)placeholders
{
    [self writeString:@"[STEvaluator interpolate:"];
    [self writeQuotedString:string];
    [self writeString:@" forObject:self locals:@{"];
    BOOL first=YES;
    NSMutableSet *bound=[NSMutableSet set];
    for (id placeholder in placeholders) {
        if ( ![self placeholderIsBareName:placeholder] ) continue;
        NSString *name=[placeholder identifierName];
        if ( [bound containsObject:name] ) continue;
        [bound addObject:name];
        if ( !first ) [self writeString:@", "];
        first=NO;
        [self writeQuotedString:name];
        [self writeString:@": "];
        [self writeInterpolationPlaceholder:placeholder];
    }
    [self writeString:@"}]"];
}

-(void)emitInterpolatedString:(id)stringLiteral { [self writeInterpolatedString:stringLiteral]; }

#pragma mark - message sends

-(void)writeKeyWord:aKeyWord andArg:arg
{
    [self writeString:@" "];
    [self writeString:aKeyWord];
    [self writeString:@":"];
    [self writeObject:arg];
}

// Legacy generation protocol the node classes call from -writeOnByteStream:; kept
// as thin shims onto the emit primitives so those paths keep working.
-(void)writeMessage:selector toReceiver:receiver withArgs:args superSend:(BOOL)isSuperSend
{
    [self emitMessageSelector:selector receiver:receiver args:args super:isSuperSend];
}

-(void)writeMessage:selector toReceiver:receiver withArgs:args
{
    [self emitMessageSelector:selector receiver:receiver args:args super:NO];
}

-(void)writeStatements:aList { [self writeStatementList:aList]; }

-(void)emitMessageSelector:(NSString*)selector receiver:(id)receiver args:(NSArray*)args super:(BOOL)isSuperSend
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

#pragma mark - assignment

-(void)emitAssignmentToLHS:(id)lhs from:(id)rhs
{
    STIdentifier *identifier=[lhs isKindOfClass:[STIdentifierExpression class]]
        ? (STIdentifier*)[(STIdentifierExpression*)lhs identifier]
        : nil;
    NSString *scheme=[identifier schemeName];
    if ( [scheme isEqual:@"this"] ) {
        // this:hi := rhs  →  [self setHi:rhs]
        NSString *name=[identifier identifierName];
        [self writeString:@"[self set"];
        [self writeString:[[name substringToIndex:1] uppercaseString]];
        [self writeString:[name substringFromIndex:1]];
        [self writeString:@":"];
        [self writeObject:rhs];
        [self writeString:@"]"];
    } else if ( scheme.length && ![scheme isEqual:@"default"] && ![scheme isEqual:@"var"] &&
        ![scheme isEqual:@"self"] ) {
        [self writeString:@"st_scheme_at_put("];
        [self writeQuotedString:scheme];
        [self writeString:@", "];
        [self writeQuotedString:[identifier identifierName]];
        [self writeString:@", "];
        [self writeObject:rhs];
        [self writeString:@")"];
    } else {
        [self writeObject:lhs];
        [self writeString:@" = "];
        [self writeObject:rhs];
    }
}

#pragma mark - blocks and collection literals

-(void)emitBlockPrologueWithArguments:(NSArray*)arguments
{
    [self writeString:@"^id("];
    for (NSUInteger i=0;i<arguments.count;i++) {
        if (i) [self writeString:@", "];
        [self writeString:@"id "];
        [self writeString:arguments[i]];
    }
    [self writeString:@") {\n"];
}

-(void)emitBlockEpilogue  { [self writeString:@"}"]; }

-(void)emitArrayLiteralOpen:(NSString*)className
{
    if (className) {
        [self writeString:@"[[["];
        [self writeString:[self mapClassName:className]];
        [self writeString:@" alloc] initWithArray:@["];
    } else {
        [self writeString:@"@["];
    }
}

-(void)emitArrayLiteralClose:(NSString*)className
{
    [self writeString:className ? @"]] autorelease]" : @"]"];
}

-(void)emitDictionaryLiteralOpen:(NSString*)className
{
    if (className) {
        [self writeString:@"[[["];
        [self writeString:[self mapClassName:className]];
        [self writeString:@" alloc] initWithDictionary:@{"];
    } else {
        [self writeString:@"@{"];
    }
}

-(void)emitDictionaryLiteralClose:(NSString*)className
{
    [self writeString:className ? @"}] autorelease]" : @"}"];
}

-(void)emitDictionaryEntryKey:(id)key value:(id)value
{
    [self writeObject:key];
    [self writeString:@": "];
    [self writeObject:value];
}

-(void)emitConnectionFrom:(id)lhs to:(id)rhs
{
    [self writeString:@"st_connect_components("];
    [self writeObject:lhs];
    [self writeString:@", "];
    [self writeObject:rhs];
    [self writeString:@")"];
}

#pragma mark - definitions

-(void)emitVariableDefinition:(STVariableDefinition*)definition
{
    // When the enclosing method has already hoisted this local (so it can be shared
    // with blocks), emit a plain assignment instead of a second declaration.
    if ( [self.declaredLocals containsObject:definition.name] ) {
        [self writeString:definition.name];
    } else {
        [self writeString:[self objectiveCTypeFor:[definition type]]];
        [self writeString:@" "];
        [self writeString:definition.name];
        [self.declaredLocals addObject:definition.name];
    }
    if (definition.initializer) {
        [self writeString:@" = "];
        [self writeObject:definition.initializer];
    }
}

-(BOOL)isLocalScheme:(NSString*)scheme
{
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
    [locals addObjectsFromArray:method.localVars];

    MPWMethodHeader *header=method.header;
    for (int i=0;i<header.numArguments;i++) {
        [locals removeObject:[header argumentNameAtIndex:i]];
    }
    if ( self.currentIvarTypes ) {
        [locals minusSet:[NSSet setWithArray:self.currentIvarTypes.allKeys]];
    }
    // Locals assigned inside a block must be __block so the mutation is shared with
    // the enclosing scope, matching the interpreter's flattened scoping.
    NSMutableSet *writtenInBlocks=[NSMutableSet set];
    for ( MPWBlockExpression *block in method.blocks ) {
        [writtenInBlocks unionSet:[self localNamesWrittenIn:[block variablesWritten]]];
        [locals removeObjectsInArray:block.arguments];
    }

    for ( NSString *name in [locals.allObjects sortedArrayUsingSelector:@selector(compare:)] ) {
        if ( [writtenInBlocks containsObject:name] ) {
            [self writeString:@"__block "];
        }
        MPWTypeDefinition *type=[self.currentTypeContext typeForName:name];
        NSString *cType=(type && type.objcTypeCode != '@') ? [self objectiveCTypeFor:type] : @"id";
        [self writeString:cType];
        [self writeString:@" "];
        [self writeString:name];
        [self writeString:@";\n"];
        [self.declaredLocals addObject:name];
    }
}

-(void)emitMethodPrologue:(STScriptedMethod*)method
{
    MPWMethodHeader *header=method.header;
    [self writeString:self.generatingClassMethod ? @"+ (" : @"- ("];
    [self writeString:[self objectiveCTypeFor:header.returnType]];
    [self writeString:@")"];
    NSArray *selectorParts=[header.methodName componentsSeparatedByString:@":"];
    if (header.numArguments == 0) {
        [self writeString:header.methodName];
    } else {
        for (int i=0;i<header.numArguments;i++) {
            if (i) [self writeString:@" "];
            [self writeString:selectorParts[i]];
            [self writeString:@":("];
            [self writeString:[self objectiveCTypeFor:[header argumentTypeAtIndex:i]]];
            [self writeString:@")"];
            [self writeString:[header argumentNameAtIndex:i]];
        }
    }
    [self writeString:@"\n{\n"];
    self.declaredLocals=[NSMutableSet set];
    [self writeLocalDeclarationsForMethod:method];
}

-(void)emitMethodEpilogue:(STScriptedMethod*)method  { [self writeString:@"}\n"]; }

-(void)emitClassDefinition:(STClassDefinition*)classDefinition
{
    [self writeString:@"@interface "];
    [self writeString:classDefinition.name];
    [self writeString:@" : "];
    [self writeString:[self mapClassName:classDefinition.superclassNameToUse]];
    NSArray *ivars=classDefinition.structureDefinition.fields;
    if (ivars.count) {
        [self writeString:@" {\n"];
        for (id ivar in ivars) {
            MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
            [self writeString:ivarType ? [self objectiveCTypeFor:ivarType] : @"id"];
            [self writeString:@" "];
            [self writeString:[ivar name]];
            [self writeString:@";\n"];
        }
        [self writeString:@"}"];
    }
    [self writeString:@"\n@end\n\n@implementation "];
    [self writeString:classDefinition.name];
    [self writeString:@"\n"];
    for (id ivar in ivars) {
        MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
        [self writeAccessorForName:[ivar name] type:ivarType];
    }
    NSMutableDictionary *ivarTypes=[NSMutableDictionary dictionary];
    for (id ivar in ivars) {
        MPWTypeDefinition *ivarType=[ivar respondsToSelector:@selector(type)] ? [ivar type] : nil;
        ivarTypes[[ivar name]]=ivarType ?: [MPWTypeDefinition idType];
    }
    NSDictionary *savedIvarTypes=self.currentIvarTypes;
    self.currentIvarTypes=ivarTypes;
    for (STScriptedMethod *method in classDefinition.methods) {
        [self writeObject:method];
    }
    self.currentIvarTypes=savedIvarTypes;
    self.generatingClassMethod=YES;
    for (STScriptedMethod *method in classDefinition.classMethods) {
        [self writeObject:method];
    }
    self.generatingClassMethod=NO;
    [self writeString:@"@end\n"];
}

#pragma mark - control-flow lowering hooks

-(void)emitBooleanCondition:(id)condition
{
    if ( [condition isKindOfClass:[STCoerce class]] && [(STCoerce*)condition isBoxing] ) {
        [self writeObject:[(STCoerce*)condition expression]];
    } else {
        [self writeString:@"["];
        [self writeObject:condition];
        [self writeString:@" boolValue]"];
    }
}

-(NSString*)loopVariableDeclaration  { return @"long "; }

-(void)emitLoopBound:bound
{
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

-(void)emitForeachStatement:(MPWMessageExpression*)doMessage
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

#pragma mark - literal leaves

-(void)emitStringLiteral:(NSString*)string  { [self writeQuotedString:string]; }

-(void)emitNumberLiteral:(NSNumber*)number
{
    [self writeString:@"@("];
    [self writeString:number.stringValue];
    [self writeString:@")"];
}

-(void)emitBooleanLiteral:(BOOL)value  { [self writeString:value ? @"@YES" : @"@NO"]; }
-(void)emitNilLiteral                  { [self writeString:@"nil"]; }
-(NSString*)nullLiteral                { return @"nil"; }

@end


#pragma mark - the single shared tree-walk

@implementation NSObject(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [self writeOnByteStream:generator]; }
@end

@implementation NSString(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitStringLiteral:self]; }
@end

@implementation NSNumber(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    if ( !strcmp(self.objCType, @encode(BOOL)) ) [generator emitBooleanLiteral:self.boolValue];
    else [generator emitNumberLiteral:self];
}
@end

@implementation MPWLiteralExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    id literal=[self theLiteral];
    if ( [literal respondsToSelector:@selector(hasSingleQuotes)] && ![literal hasSingleQuotes] ) {
        [generator emitInterpolatedString:literal];
    } else {
        [generator writeObject:literal];
    }
}
@end

@implementation STIdentifierExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitIdentifier:self.identifier]; }
@end

@implementation MPWAssignmentExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitAssignmentToLHS:self.lhs from:self.rhs]; }
@end

@implementation MPWMessageExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    [generator emitMessageSelector:NSStringFromSelector(self.selector)
                          receiver:self.receiver args:self.args super:self.isSuperSend];
}
@end

@implementation STPrimitiveMessageExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitPrimitiveMessage:self]; }
@end

@implementation STCoerce(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitCoerce:self]; }
@end

@implementation MPWBlockExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    [generator emitBlockPrologueWithArguments:self.arguments];
    [generator writeStatements:self.statementArray returningLast:YES];
    [generator emitBlockEpilogue];
}
@end

@implementation MPWStatementList(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator writeStatementList:self.statements]; }
@end

@implementation MPWLiteralArrayExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    [generator emitArrayLiteralOpen:self.literalClassName];
    for (NSUInteger i=0;i<self.objects.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:self.objects[i]];
    }
    [generator emitArrayLiteralClose:self.literalClassName];
}
@end

@implementation MPWLiteralDictionaryExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    NSArray *keys=[self valueForKey:@"keys"], *values=[self valueForKey:@"values"];
    [generator emitDictionaryLiteralOpen:self.literalClassName];
    NSUInteger count=MIN(keys.count, values.count);
    for (NSUInteger i=0;i<count;i++) {
        if (i) [generator writeString:@", "];
        [generator emitDictionaryEntryKey:keys[i] value:values[i]];
    }
    [generator emitDictionaryLiteralClose:self.literalClassName];
}
@end

@implementation STSubscriptExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    [generator writeObject:self.receiver];
    [generator writeString:@"["];
    [generator writeObject:self.subscript];
    [generator writeString:@"]"];
}
@end

@implementation MPWCascadeExpression(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
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

@implementation STConnectionDefiner(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitConnectionFrom:self.lhs to:self.rhs]; }
@end

@implementation STVariableDefinition(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitVariableDefinition:self]; }
@end

@implementation STScriptedMethod(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator
{
    MPWMethodHeader *header=self.header;
    // Both backends run the same static type-inference / lowering pass.  Idempotent.
    STTypeContext *typeContext=[STTypeContext contextForMethod:self];
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

    [generator emitMethodPrologue:self];
    id body=self.methodBody;
    NSArray *statements=[body isKindOfClass:[MPWStatementList class]] ? [body statements] : @[ body ];
    [generator writeStatements:statements returningLast:header.returnType.objcTypeCode != 'v'];
    [generator emitMethodEpilogue:self];

    generator.currentTypeContext=savedContext;
}
@end

@implementation STClassDefinition(codegen)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator { [generator emitClassDefinition:self]; }
@end
