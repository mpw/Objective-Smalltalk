//
//  STNativeCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.10.22.
//

#import "STNativeCompiler.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "MPWMachOWriter.h"
#import "MPWARMObjectCodeGenerator.h"
#import "MPWMachOClassWriter.h"
#import <ObjectiveSmalltalk/MPWMessageExpression.h>
#import <ObjectiveSmalltalk/MPWLiteralExpression.h>
#import <ObjectiveSmalltalk/MPWIdentifierExpression.h>


@interface STNativeCompiler()

-(void)generateCodeForExpression:(MPWExpression*)expression;
-(void)generateCodeFor:(MPWExpression*)someExpression;
-(void)generateIdentifierExpression:(MPWIdentifierExpression*)expr;
-(void)generateMessageSend:(MPWMessageExpression*)expr;

@end


 
@interface MPWExpression(nativeCode)
-(void)generateNativeCodeOn:(STNativeCompiler*)compiler;

@end

@implementation MPWExpression(nativeCode)

-(void)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    [compiler generateCodeForExpression:self];
}

@end
@implementation MPWStatementList(nativeCode)

-(void)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    for ( id statement in self.statements ) {
        [compiler generateCodeFor:statement];
    }
}

@end
@implementation MPWMessageExpression(nativeCode)

-(void)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    [compiler generateMessageSend:self];
}

@end

@implementation MPWIdentifierExpression(nativeCode)

-(void)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    [compiler generateIdentifierExpression:self];
}

@end



@implementation STNativeCompiler
{
    MPWARMObjectCodeGenerator* codegen;
    MPWMachOWriter *writer;
    MPWMachOClassWriter *classwriter;
}

objectAccessor(MPWARMObjectCodeGenerator*, codegen, setCodegen)
objectAccessor(MPWMachOWriter*, writer, setWriter)
objectAccessor(MPWMachOClassWriter*, classwriter, setClasswriter)

-(instancetype)init
{
    self=[super init];
    if ( self ) {
        self.writer = [MPWMachOWriter stream];
        self.classwriter = [MPWMachOClassWriter writerWithWriter:writer];
        self.codegen = [MPWARMObjectCodeGenerator stream];
        
        codegen.symbolWriter = writer;
        codegen.relocationWriter = writer.textSectionWriter;
    }
    return self;
}

-(void)generateIdentifierExpression:(MPWIdentifierExpression*)expr
{
    // this should do something
}

-(void)generateCodeForExpression:(MPWExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't yet compile code for %@/%@",expression.class,expression];
}


-(void)generateMessageSend:(MPWMessageExpression*)expr
{
    NSString *selectorString = NSStringFromSelector(expr.selector);
    [expr.receiver generateNativeCodeOn:self];

    if (  [selectorString isEqual:@"add:"] ) {
        id arg=expr.args[0];
        if ( [arg isKindOfClass:[MPWLiteralExpression class]]) {
            MPWLiteralExpression *lit=(MPWLiteralExpression*)arg;
            [codegen generateAddDest:0 source:0 immediate:[[lit theLiteral] intValue]];
        }
    } else {
        [codegen generateMessageSendToSelector:selectorString];
    }
}

-(void)generateCodeFor:(MPWExpression*)someExpression
{
    [someExpression generateNativeCodeOn:self];
}

-(void)writeMethodBody:(MPWScriptedMethod*)method
{
    [method.methodBody generateNativeCodeOn:self];
}

-(NSData*)compileClassToMachoO:(MPWClassDefinition*)aClass
{
    classwriter.nameOfClass = aClass.name;
    classwriter.nameOfSuperClass = aClass.superclassName;
    NSMutableArray *symbolNames=[NSMutableArray array];
    NSMutableArray *methodNames=[NSMutableArray array];
    NSMutableArray *methodTypes=[NSMutableArray array];
    for ( MPWScriptedMethod* method in aClass.methods) {
        [methodNames addObject:method.methodName];
        [methodTypes addObject:[[method header] typeString]];
        
        NSString *symbol=[NSString stringWithFormat:@"-[%@ %@]",aClass.name,method.methodName];
        [codegen generateFunctionNamed:symbol body:^(MPWARMObjectCodeGenerator * _Nonnull gen) {
            [self writeMethodBody:method];
        }];
        [symbolNames addObject:symbol];
    }
    [writer addTextSectionData:[codegen target]];
    [classwriter writeInstanceMethodListForMethodNames:methodNames types:methodTypes functions:symbolNames ];
    [classwriter writeClass];
    [writer writeFile];
    return (NSData*)[writer target];
}


@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"

@implementation STNativeCompiler(testing) 

+(void)testCompileSimpleClassAndMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@" class TestClass : NSObject {  -<int>hashPlus200  { self hash + 200. }}"];
    IDEXPECT( compiledClass.name, @"TestClass", @"top level result");
    INTEXPECT( compiledClass.methods.count,1,@"method count");
    INTEXPECT( compiledClass.classMethods.count,0,@"class method count");
    NSData *macho=[compiler compileClassToMachoO:compiledClass];
    [macho writeToFile:@"/tmp/testclass-from-source.o" atomically:YES];
    MPWMachOReader *reader = [MPWMachOReader readerWithData:macho];
    EXPECTTRUE(reader.isHeaderValid, @"got a macho");
    INTEXPECT([reader classReaders].count,1,@"number of classes" );
    MPWMachOClassReader *classReader = [reader classReaders].firstObject;
    IDEXPECT(classReader.nameOfClass, @"TestClass", @"name of class");
    IDEXPECT(classReader.superclassPointer.targetName, @"_OBJC_CLASS_$_NSObject", @"symbol for superclass");
    INTEXPECT(classReader.numberOfMethods, 1,@"number of methods");
    IDEXPECT([classReader methodNameAt:0].targetPointer.stringValue,@"hashPlus200",@"name of method");
    IDEXPECT([classReader methodTypesAt:0].targetPointer.stringValue,@"l@:",@"type of method");
    IDEXPECT([classReader methodCodeAt:0].targetName,@"-[TestClass hashPlus200]",@"symbol for method code");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCompileSimpleClassAndMethod",
			];
}

@end
