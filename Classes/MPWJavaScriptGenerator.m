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
@property (nonatomic, strong) NSString *currentClassName;
@property (nonatomic, strong) NSString *currentSuperclassName;
-(void)writeJavaScriptString:(NSString*)string;
-(void)writeMethod:(STScriptedMethod*)method className:(NSString*)className;
@end

@implementation MPWJavaScriptGenerator

+defaultTarget { return [NSMutableString string]; }
-(SEL)streamWriterMessage { return @selector(generateJavaScriptOn:); }

+(NSString*)transpile:(NSString*)source
{
    NSMutableString *javascript=[NSMutableString string];
    MPWJavaScriptGenerator *generator=[self streamWithTarget:javascript];
    [generator writeObject:[[STCompiler compiler] compile:source]];
    return javascript;
}

+testSelectors
{
    return @[];
}

-(void)writeJavaScriptString:(NSString*)source
{
    NSData *data=[NSJSONSerialization dataWithJSONObject:@[ source ?: @"" ] options:0 error:NULL];
    NSString *array=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    [self writeString:[array substringWithRange:NSMakeRange(1, array.length-2)]];
}

-(void)generateIdentifier:(STIdentifier*)identifier
{
    NSString *scheme=identifier.schemeName;
    NSString *name=identifier.identifierName;
    if ([name isEqual:@"nil"]) [self writeString:@"null"];
    else if ([name isEqual:@"true"]) [self writeString:@"true"];
    else if ([name isEqual:@"false"]) [self writeString:@"false"];
    else if (scheme.length == 0 || [scheme isEqual:@"default"] || [scheme isEqual:@"var"] ||
             [scheme isEqual:@"self"] || [scheme isEqual:@"this"] || [scheme isEqual:@"class"]) {
        [self writeString:name];
    } else {
        [self writeString:@"objst_scheme_get("];
        [self writeJavaScriptString:scheme];
        [self writeString:@", "];
        [self writeJavaScriptString:name];
        [self writeString:@")"];
    }
}

-(void)writeArguments:(NSArray*)args
{
    for (NSUInteger i=0;i<args.count;i++) {
        [self writeString:@", "];
        [self writeObject:args[i]];
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
    if (isSuperSend) {
        [self writeString:@"objj_msgSendSuper({ receiver: self, super_class: objj_getClass("];
        [self writeJavaScriptString:self.currentSuperclassName];
        [self writeString:@") }, "];
        [self writeJavaScriptString:selector];
        [self writeArguments:args];
        [self writeString:@")"];
        return;
    }
    [self writeString:@"("];
    [self writeObject:receiver];
    [self writeString:@" == null ? "];
    [self writeObject:receiver];
    [self writeString:@" : "];
    [self writeObject:receiver];
    [self writeString:@".isa.objj_msgSend("];
    [self writeObject:receiver];
    [self writeString:@", "];
    [self writeJavaScriptString:selector];
    [self writeArguments:args];
    [self writeString:@"))"];
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
        [self writeString:@"return null;\n"];
}

-(void)writeMethod:(STScriptedMethod*)method className:(NSString*)className
{
    MPWMethodHeader *header=method.header;
    NSString *selector=header.methodName;
    [self writeString:@"new objj_method(sel_getUid("];
    [self writeJavaScriptString:selector];
    [self writeString:@"), function $"];
    [self writeString:className];
    [self writeString:@"__"];
    [self writeString:[selector stringByReplacingOccurrencesOfString:@":" withString:@"_"]];
    [self writeString:@"(self, _cmd"];
    for (int i=0;i<header.numArguments;i++) {
        [self writeString:@", "];
        [self writeString:[header argumentNameAtIndex:i]];
    }
    [self writeString:@") {\n"];
    NSArray *body=[method.methodBody isKindOfClass:[MPWStatementList class]] ? [(MPWStatementList*)method.methodBody statements] : @[ method.methodBody ];
    [self writeStatements:body returningLast:header.returnType.objcTypeCode != 'v'];
    [self writeString:@"}, ["];
    [self writeJavaScriptString:header.returnType.name ?: @"id"];
    for (int i=0;i<header.numArguments;i++) {
        [self writeString:@", "];
        [self writeJavaScriptString:[header argumentTypeNameAtIndex:i] ?: @"id"];
    }
    [self writeString:@"])"];
}

-(void)dealloc
{
    [_currentClassName release];
    [_currentSuperclassName release];
    [super dealloc];
}

@end

@implementation NSObject(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [self writeOnByteStream:generator]; }
@end

@implementation NSString(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator { [generator writeJavaScriptString:self]; }
@end

@implementation NSNumber(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    if (!strcmp(self.objCType, @encode(BOOL))) [generator writeString:self.boolValue ? @"true" : @"false"];
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
    [generator writeObject:self.lhs]; [generator writeString:@" = "]; [generator writeObject:self.rhs];
}
@end

@implementation MPWMessageExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    [generator writeMessage:NSStringFromSelector(self.selector) toReceiver:self.receiver withArgs:self.args superSend:self.isSuperSend];
}
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
    [generator writeString:@"["];
    for (NSUInteger i=0;i<self.objects.count;i++) { if (i) [generator writeString:@", "]; [generator writeObject:self.objects[i]]; }
    [generator writeString:@"]"];
}
@end

@implementation MPWLiteralDictionaryExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    NSArray *keys=[self valueForKey:@"keys"], *values=[self valueForKey:@"values"];
    [generator writeString:@"{"];
    for (NSUInteger i=0;i<MIN(keys.count, values.count);i++) {
        if (i) [generator writeString:@", "];
        [generator writeString:@"["]; [generator writeObject:keys[i]]; [generator writeString:@"]: "]; [generator writeObject:values[i]];
    }
    [generator writeString:@"}"];
}
@end

@implementation STSubscriptExpression(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{ [generator writeObject:self.receiver]; [generator writeString:@"["]; [generator writeObject:self.subscript]; [generator writeString:@"]"]; }
@end

@implementation STVariableDefinition(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    [generator writeString:@"var "]; [generator writeString:self.name];
    if (self.initializer) { [generator writeString:@" = "]; [generator writeObject:self.initializer]; }
}
@end

@implementation STClassDefinition(generateJavaScriptOn)
-(void)generateJavaScriptOn:(MPWJavaScriptGenerator*)generator
{
    generator.currentClassName=self.name;
    generator.currentSuperclassName=self.superclassNameToUse;
    [generator writeString:@"{var the_class = objj_allocateClassPair(objj_getClass("];
    [generator writeJavaScriptString:self.superclassNameToUse];
    [generator writeString:@"), "];
    [generator writeJavaScriptString:self.name];
    [generator writeString:@"),\nmeta_class = the_class.isa;\n"];
    NSArray *ivars=self.structureDefinition.fields;
    if (ivars.count) {
        [generator writeString:@"class_addIvars(the_class, ["];
        for (NSUInteger i=0;i<ivars.count;i++) {
            id ivar=ivars[i]; if (i) [generator writeString:@", "];
            [generator writeString:@"new objj_ivar("]; [generator writeJavaScriptString:[ivar name]]; [generator writeString:@", "];
            [generator writeJavaScriptString:[ivar respondsToSelector:@selector(typeName)] ? [ivar typeName] : @"id"]; [generator writeString:@")"];
        }
        [generator writeString:@"]);\n"];
    }
    if (self.methods.count) {
        [generator writeString:@"class_addMethods(the_class, ["];
        for (NSUInteger i=0;i<self.methods.count;i++) { if (i) [generator writeString:@",\n"]; [generator writeMethod:self.methods[i] className:self.name]; }
        [generator writeString:@"]);\n"];
    }
    if (self.classMethods.count) {
        [generator writeString:@"class_addMethods(meta_class, ["];
        for (NSUInteger i=0;i<self.classMethods.count;i++) { if (i) [generator writeString:@",\n"]; [generator writeMethod:self.classMethods[i] className:self.name]; }
        [generator writeString:@"]);\n"];
    }
    [generator writeString:@"objj_registerClassPair(the_class);\n}\n"];
}
@end
