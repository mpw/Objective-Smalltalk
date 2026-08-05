#import "MPWJavaScriptGenerator.h"
#import "MPWAssignmentExpression.h"
#import "MPWBlockExpression.h"
#import "MPWCascadeExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWLiteralDictionaryExpression.h"
#import "MPWLiteralExpression.h"
#import "MPWMessageExpression.h"
#import "MPWMethodHeader.h"
#import "MPWStatementList.h"
#import "STClassDefinition.h"
#import "STCompiler.h"
#import "STConnectionDefiner.h"
#import "STExpression.h"
#import "STIdentifier.h"
#import "STIdentifierExpression.h"
#import "STScriptedMethod.h"
#import "STSubscriptExpression.h"
#import "STTypeDescriptor.h"
#import "STVariableDefinition.h"

@interface NSObject(MPWJavaScriptGenerating)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator;
@end

@interface MPWJavaScriptGenerator ()
@property (nonatomic, assign) NSSet *currentIvarNames;
@property (nonatomic, assign) NSMutableSet *declaredLocals;
-(void)writeObjectiveJString:(NSString*)string;
-(void)writeMethod:(STScriptedMethod*)method classMethod:(BOOL)isClassMethod;
-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method;
@end

@implementation MPWJavaScriptGenerator

+defaultTarget { return [NSMutableString string]; }
-(SEL)streamWriterMessage { return @selector(generateJavaScriptOn:); }

+(NSString*)transpile:(NSString*)source
{
    return [self transpileToObjectiveJ:source];
}

+(NSString*)transpileToObjectiveJ:(NSString*)source
{
    NSMutableString *objectiveJ=[NSMutableString string];
    MPWJavaScriptGenerator *generator=[self streamWithTarget:objectiveJ];
    [generator writeObject:[[STCompiler compiler] compile:source]];
    return objectiveJ;
}

+testSelectors { return @[]; }

-(void)writeObjectiveJString:(NSString*)source
{
    NSData *data=[NSJSONSerialization dataWithJSONObject:@[ source ?: @"" ] options:0 error:NULL];
    NSString *array=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [self writeString:@"@"];
    [self writeString:[array substringWithRange:NSMakeRange(1, array.length-2)]];
}

-(void)generateIdentifier:(STIdentifier*)identifier
{
    NSString *scheme=identifier.schemeName;
    NSString *name=identifier.identifierName;
    if ([name isEqual:@"nil"]) [self writeString:@"nil"];
    else if ([name isEqual:@"true"]) [self writeString:@"YES"];
    else if ([name isEqual:@"false"]) [self writeString:@"NO"];
    else if (scheme.length == 0 || [scheme isEqual:@"default"] || [scheme isEqual:@"var"] ||
             [scheme isEqual:@"self"] || [scheme isEqual:@"this"] || [scheme isEqual:@"class"]) {
        [self writeString:name];
    } else {
        [self writeString:@"objst_scheme_get("];
        [self writeObjectiveJString:scheme];
        [self writeString:@", "];
        [self writeObjectiveJString:name];
        [self writeString:@")"];
    }
}

-(void)writeMessage:(NSString*)selector toReceiver:(id)receiver withArgs:(NSArray*)args superSend:(BOOL)isSuperSend
{
    if ([selector isEqual:@"forward:"] && [receiver isKindOfClass:[STIdentifierExpression class]] &&
        [[(STIdentifier*)[receiver identifier] identifierName] isEqual:@"self"]) {
        [self writeString:@"return "];
        [self writeObject:[args isKindOfClass:[NSArray class]] ? args[0] : args];
        return;
    }
    if ([receiver isKindOfClass:[MPWBlockExpression class]] &&
        ([selector isEqual:@"value"] || [selector hasPrefix:@"value:"])) {
        [self writeString:@"("];
        [self writeObject:receiver];
        [self writeString:@")("];
        for (NSUInteger i=0;i<args.count;i++) {
            if (i) [self writeString:@", "];
            [self writeObject:args[i]];
        }
        [self writeString:@")"];
        return;
    }
    [self writeString:@"["];
    if (isSuperSend) [self writeString:@"super"];
    else [self writeObject:receiver];
    if (args.count == 0) {
        [self writeString:@" "];
        [self writeString:selector];
    } else {
        NSArray *parts=[selector componentsSeparatedByString:@":"];
        for (NSUInteger i=0;i<args.count;i++) {
            [self writeString:@" "];
            [self writeString:i < parts.count ? parts[i] : @""];
            [self writeString:@":"];
            [self writeObject:args[i]];
        }
    }
    [self writeString:@"]"];
}

-(void)writeStatements:(NSArray*)statements returningLast:(BOOL)returnLast
{
    for (NSUInteger i=0;i<statements.count;i++) {
        id statement=statements[i];
        BOOL shouldReturn=returnLast && i == statements.count-1 && ![statement isKindOfClass:[STVariableDefinition class]];
        if (shouldReturn) [self writeString:@"return "];
        [self writeObject:statement];
        [self writeString:@";\n"];
    }
    if (returnLast && (statements.count == 0 || [statements.lastObject isKindOfClass:[STVariableDefinition class]]))
        [self writeString:@"return nil;\n"];
}

-(BOOL)isLocalScheme:(NSString*)scheme
{
    return scheme.length == 0 || [scheme isEqual:@"default"] || [scheme isEqual:@"var"];
}

-(NSSet*)localNamesWrittenIn:(NSSet*)writtenIdentifiers
{
    NSMutableSet *names=[NSMutableSet set];
    for (id identifier in writtenIdentifiers) {
        if ([identifier respondsToSelector:@selector(schemeName)] &&
            [self isLocalScheme:[identifier schemeName]]) {
            [names addObject:[identifier identifierName]];
        }
    }
    return names;
}

-(void)writeLocalDeclarationsForMethod:(STScriptedMethod*)method
{
    STExpression *body=method.methodBody;
    NSMutableSet *locals=[[[self localNamesWrittenIn:[body variablesWritten]] mutableCopy] autorelease];
    [locals addObjectsFromArray:method.localVars];
    for (int i=0;i<method.header.numArguments;i++)
        [locals removeObject:[method.header argumentNameAtIndex:i]];
    if (self.currentIvarNames) [locals minusSet:self.currentIvarNames];
    for (MPWBlockExpression *block in method.blocks)
        [locals removeObjectsInArray:block.arguments];
    for (NSString *name in [locals.allObjects sortedArrayUsingSelector:@selector(compare:)]) {
        [self writeString:@"var "];
        [self writeString:name];
        [self writeString:@";\n"];
        [self.declaredLocals addObject:name];
    }
}

-(void)writeMethod:(STScriptedMethod*)method classMethod:(BOOL)isClassMethod
{
    MPWMethodHeader *header=method.header;
    [self writeString:isClassMethod ? @"+ (" : @"- ("];
    [self writeString:header.returnType.name ?: @"id"];
    [self writeString:@")"];
    if (header.numArguments == 0) {
        [self writeString:header.methodName];
    } else {
        NSArray *parts=[header.methodName componentsSeparatedByString:@":"];
        for (int i=0;i<header.numArguments;i++) {
            if (i) [self writeString:@" "];
            [self writeString:parts[i]];
            [self writeString:@":("];
            [self writeString:[header argumentTypeNameAtIndex:i] ?: @"id"];
            [self writeString:@")"];
            [self writeString:[header argumentNameAtIndex:i]];
        }
    }
    [self writeString:@"\n{\n"];
    NSArray *body=[method.methodBody isKindOfClass:[MPWStatementList class]]
        ? [(MPWStatementList*)method.methodBody statements] : @[ method.methodBody ];
    NSMutableSet *savedLocals=self.declaredLocals;
    self.declaredLocals=[NSMutableSet set];
    [self writeLocalDeclarationsForMethod:method];
    [self writeStatements:body returningLast:header.returnType.objcTypeCode != 'v'];
    [self writeString:@"}\n"];
    self.declaredLocals=savedLocals;
}

@end

@implementation NSObject(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [self writeOnByteStream:generator]; }
@end

@implementation NSString(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator writeObjectiveJString:self]; }
@end

@implementation NSNumber(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    if (!strcmp(self.objCType, @encode(BOOL))) [generator writeString:self.boolValue ? @"YES" : @"NO"];
    else [generator writeString:self.stringValue];
}
@end

@implementation MPWLiteralExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator writeObject:self.theLiteral]; }
@end

@implementation STIdentifierExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator generateIdentifier:self.identifier]; }
@end

@implementation MPWAssignmentExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    STIdentifier *identifier=[self.lhs isKindOfClass:[STIdentifierExpression class]]
        ? (STIdentifier*)[(STIdentifierExpression*)self.lhs identifier] : nil;
    NSString *scheme=identifier.schemeName;
    if (scheme.length && ![scheme isEqual:@"default"] && ![scheme isEqual:@"var"] &&
        ![scheme isEqual:@"self"] && ![scheme isEqual:@"this"]) {
        [generator writeString:@"objst_scheme_set("];
        [generator writeObjectiveJString:scheme];
        [generator writeString:@", "];
        [generator writeObjectiveJString:identifier.identifierName];
        [generator writeString:@", "];
        [generator writeObject:self.rhs];
        [generator writeString:@")"];
    } else {
        [generator writeObject:self.lhs]; [generator writeString:@" = "]; [generator writeObject:self.rhs];
    }
}
@end

@implementation MPWMessageExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{ [generator writeMessage:NSStringFromSelector(self.selector) toReceiver:self.receiver withArgs:self.args superSend:self.isSuperSend]; }
@end

@implementation MPWBlockExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    [generator writeString:@"function("];
    for (NSUInteger i=0;i<self.arguments.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeString:self.arguments[i]];
    }
    [generator writeString:@") {\n"];
    [generator writeStatements:self.statementArray returningLast:YES];
    [generator writeString:@"}"];
}
@end

@implementation MPWStatementList(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator writeStatements:self.statements returningLast:NO]; }
@end

@implementation MPWLiteralArrayExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    if (self.literalClassName) {
        [generator writeString:@"[["];
        [generator writeString:self.literalClassName];
        [generator writeString:@" alloc] initWithArray:@["];
    } else [generator writeString:@"@["];
    for (NSUInteger i=0;i<self.objects.count;i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:self.objects[i]];
    }
    [generator writeString:self.literalClassName ? @"]]" : @"]"];
}
@end

@implementation MPWLiteralDictionaryExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    NSArray *keys=[self valueForKey:@"keys"], *values=[self valueForKey:@"values"];
    if (self.literalClassName) {
        [generator writeString:@"[["];
        [generator writeString:self.literalClassName];
        [generator writeString:@" alloc] initWithDictionary:@{"];
    } else [generator writeString:@"@{"];
    for (NSUInteger i=0;i<MIN(keys.count, values.count);i++) {
        if (i) [generator writeString:@", "];
        [generator writeObject:keys[i]]; [generator writeString:@": "]; [generator writeObject:values[i]];
    }
    [generator writeString:self.literalClassName ? @"}]" : @"}"];
}
@end

@implementation STSubscriptExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{ [generator writeObject:self.receiver]; [generator writeString:@"["]; [generator writeObject:self.subscript]; [generator writeString:@"]"]; }
@end

@implementation STConnectionDefiner(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{ [generator writeString:@"objst_connect_components("]; [generator writeObject:self.lhs]; [generator writeString:@", "]; [generator writeObject:self.rhs]; [generator writeString:@")"]; }
@end

@implementation MPWCascadeExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    NSArray *messages=[self valueForKey:@"messageExpressions"];
    [generator writeString:@"("];
    for (NSUInteger i=0;i<messages.count;i++) { if (i) [generator writeString:@", "]; [generator writeObject:messages[i]]; }
    [generator writeString:@")"];
}
@end

@implementation STVariableDefinition(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    if ([generator.declaredLocals containsObject:self.name]) [generator writeString:self.name];
    else { [generator writeString:@"var "]; [generator writeString:self.name]; [generator.declaredLocals addObject:self.name]; }
    if (self.initializer) { [generator writeString:@" = "]; [generator writeObject:self.initializer]; }
}
@end

@implementation STScriptedMethod(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator writeMethod:self classMethod:NO]; }
@end

@implementation STClassDefinition(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    [generator writeString:@"@implementation "];
    [generator writeString:self.name];
    [generator writeString:@" : "];
    [generator writeString:self.superclassNameToUse];
    NSArray *ivars=self.structureDefinition.fields;
    if (ivars.count) {
        [generator writeString:@"\n{\n"];
        for (id ivar in ivars) {
            [generator writeString:[ivar respondsToSelector:@selector(typeName)] ? ([ivar typeName] ?: @"id") : @"id"];
            [generator writeString:@" "];
            [generator writeString:[ivar name]];
            [generator writeString:@";\n"];
        }
        [generator writeString:@"}\n"];
    } else [generator writeString:@"\n"];
    NSMutableSet *ivarNames=[NSMutableSet set];
    for (id ivar in ivars) [ivarNames addObject:[ivar name]];
    NSSet *savedIvars=generator.currentIvarNames;
    generator.currentIvarNames=ivarNames;
    for (STScriptedMethod *method in self.methods) [generator writeMethod:method classMethod:NO];
    generator.currentIvarNames=savedIvars;
    for (STScriptedMethod *method in self.classMethods) [generator writeMethod:method classMethod:YES];
    [generator writeString:@"@end\n"];
}
@end
