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
#import "STSubscriptExpression.h"
#import "STTypeDescriptor.h"
#import "STVariableDefinition.h"

@interface MPWObjCGenerator ()
-(NSString*)objectiveCTypeFor:(MPWTypeDefinition*)type;
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
    if ( type.objcTypeCode == '@' && ![name isEqual:@"id"] && ![name hasSuffix:@"*"] ) {
        return [name stringByAppendingString:@" *"];
    }
    return name;
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
    NSString *typeName=[generator objectiveCTypeFor:[self type]];
    [generator writeString:typeName];
    [generator writeString:@" "];
    [generator writeString:self.name];
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
    id body=self.methodBody;
    NSArray *statements=[body isKindOfClass:[MPWStatementList class]] ? [body statements] : @[ body ];
    BOOL returnsValue=header.returnType.objcTypeCode != 'v';
    [generator writeStatements:statements returningLast:returnsValue];
    [generator writeString:@"}\n"];
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
    for (STScriptedMethod *method in self.methods) {
        [generator writeObject:method];
    }
    for (STScriptedMethod *method in self.classMethods) {
        NSMutableString *methodCode=[NSMutableString stringWithString:[MPWObjCGenerator process:method]];
        if ([methodCode hasPrefix:@"-"]) [methodCode replaceCharactersInRange:NSMakeRange(0, 1) withString:@"+"];
        [generator writeString:methodCode];
    }
    [generator writeString:@"@end\n"];
}

@end
