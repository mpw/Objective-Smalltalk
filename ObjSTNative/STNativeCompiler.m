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

-(int)generateCodeForExpression:(MPWExpression*)expression;
-(int)generateCodeFor:(MPWExpression*)someExpression;
-(int)generateIdentifierExpression:(MPWIdentifierExpression*)expr;
-(int)generateMessageSend:(MPWMessageExpression*)expr;
-(int)generateLiteralExpression:(MPWLiteralExpression*)expr;

@property (nonatomic,strong) NSMutableDictionary *variableToRegisterMap;

@end


 
@interface MPWExpression(nativeCode)
-(int)generateNativeCodeOn:(STNativeCompiler*)compiler;

@end

@implementation MPWExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateCodeForExpression:self];
}

@end
@implementation MPWStatementList(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    int returnRegister=0;
    for ( id statement in self.statements ) {
        returnRegister=[compiler generateCodeFor:statement];
    }
    return returnRegister;
}

@end
@implementation MPWMessageExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateMessageSend:self];
}

@end

@implementation MPWIdentifierExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateIdentifierExpression:self];
}

@end

@implementation MPWLiteralExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateLiteralExpression:self];
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

-(int)generateIdentifierExpression:(MPWIdentifierExpression*)expr
{
    NSString *name=[[expr identifier] stringValue];
    NSNumber *registerNumber =  self.variableToRegisterMap[name];
    if ( registerNumber ) {
        return registerNumber.intValue;
    }  else {
        [NSException raise:@"unknown" format:@"not found, identifier: %@ in names: %@",name,self.variableToRegisterMap];
        return 0;
    }
}


-(int)generateLiteralExpression:(MPWLiteralExpression*)expr
{
    id theLiteral=expr.theLiteral;
    if ( [theLiteral isKindOfClass:[NSNumber class]]) {
        int value = [theLiteral intValue];
        if ( value <= 0xffff) {
            [codegen generateMoveConstant:value to:0];
            if (self.jit) {
                [codegen loadRegister:9 withConstantAdress:MPWCreateInteger];
                [codegen generateBranchAndLinkWithRegister:9];
            } else {
                [codegen generateCallToExternalFunctionNamed:@"_MPWCreateInteger"];
            }
            return 0;
        }
    } else  if ( [theLiteral isKindOfClass:[NSString class]] ) {
        [NSException raise:@"unsupported" format:@"don't know how to compile string literal: %@  (%@):",theLiteral,[theLiteral class]];
    }
    [NSException raise:@"unsupported" format:@"don't know how to compile literal: %@  (%@):",theLiteral,[theLiteral class]];
    return 0;
}


-(int)generateCodeForExpression:(MPWExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't yet compile code for %@/%@",expression.class,expression];
    return 0;
}

-(void)moveRegister:(int)source toRegister:(int)dest
{
    if (source != dest) {
        [codegen generateMoveRegisterFrom:source to:dest];
    }
}


-(int)generateMessageSend:(MPWMessageExpression*)expr
{
    NSString *selectorString = NSStringFromSelector(expr.selector);
    [expr.receiver generateNativeCodeOn:self];

    if (  NO &&  [selectorString isEqual:@"add:"] ) {
        id arg=expr.args[0];
        if ( [arg isKindOfClass:[MPWLiteralExpression class]]) {
            MPWLiteralExpression *lit=(MPWLiteralExpression*)arg;
            [codegen generateAddDest:0 source:0 immediate:[[lit theLiteral] intValue]];
            return 0;
        } else {
            [NSException raise:@"unhandled" format:@"Only handling adds with constant right now"];
        }
    } else {
        //  FIXME:  code that comes later can clobber register 0
        //          but it can also clobber the current source
        int receiverRegister = [self generateCodeFor:expr.receiver];
        [self moveRegister:receiverRegister toRegister:0];
        for (int i=0;i<expr.args.count;i++) {
            int argRegister = [self generateCodeFor:expr.args[i]];
            [self moveRegister:argRegister toRegister:2+i];
        }
        if ( self.jit ) {
            [codegen generateJittedMessageSendToSelector:selectorString];
        } else {
            [codegen generateMessageSendToSelector:selectorString];
        }
        return 0;
    }
    return 0;
}

-(int)generateCodeFor:(MPWExpression*)someExpression
{
    return [someExpression generateNativeCodeOn:self];
}

-(int)writeMethodBody:(MPWScriptedMethod*)method
{
    return [method.methodBody generateNativeCodeOn:self];
}

-(NSString*)compileMethod:(MPWScriptedMethod*)method inClass:(MPWClassDefinition*)aClass
{
    NSString *symbol = [NSString stringWithFormat:@"-[%@ %@]",aClass.name,method.methodName];
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
    self.variableToRegisterMap[@"self"]=@(0);
    for (int i=0;i<method.methodHeader.numArguments;i++) {
        self.variableToRegisterMap[[method.methodHeader argumentNameAtIndex:i]]=@(i+2);
    }
    [codegen generateFunctionNamed:symbol body:^(MPWARMObjectCodeGenerator * _Nonnull gen) {
        [self writeMethodBody:method];
    }];
    return symbol;
}

-(MPWJittableData*)compiledCodeForMethod:(MPWScriptedMethod*)method inClass:(MPWClassDefinition*)aClass
{
    [self compileMethod:method inClass:aClass];
    return self.codegen.generatedCode;
}


-(void)compileMethodsForClass:(MPWClassDefinition*)aClass
{
    NSMutableArray *symbolNames=[NSMutableArray array];
    NSMutableArray *methodNames=[NSMutableArray array];
    NSMutableArray *methodTypes=[NSMutableArray array];
    for ( MPWScriptedMethod* method in aClass.methods) {
        [methodNames addObject:method.methodName];
        [methodTypes addObject:[[method header] typeString]];
        [symbolNames addObject:[self compileMethod:method inClass:(MPWClassDefinition*)aClass]];
    }
    [writer addTextSectionData:[codegen target]];
    [classwriter writeInstanceMethodListForMethodNames:methodNames types:methodTypes functions:symbolNames ];
}

-(void)compileClass:(MPWClassDefinition*)aClass
{
    classwriter.nameOfClass = aClass.name;
    classwriter.nameOfSuperClass = aClass.superclassNameToUse;
    [self compileMethodsForClass:aClass];
    [classwriter writeClass];
    [writer writeFile];
}

-(NSData*)compileClassToMachoO:(MPWClassDefinition*)aClass
{
    [self compileClass:aClass];
    return (NSData*)[writer target];
}


@end


#import <MPWFoundation/DebugMacros.h>
#import "MPWMachOReader.h"
#import "MPWMachOClassReader.h"
#import "MPWMachORelocationPointer.h"
#import "MPWMachOInSectionPointer.h"
#import "MPWJittableData.h"

@interface ConcatterTest1: NSObject
@end
@interface ConcatterTest1(dynamic)
-concat:a and:b;
-concat:a also:b;
-(NSNumber*)theAnswer;
-(NSString*)stringAnswer;
@end
@implementation ConcatterTest1
@end

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

+(void)testCompileMethodWithMultipleArgs
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class Concatter { -concat:a and:b { a, b. }}"];
    IDEXPECT( compiledClass.name, @"Concatter", @"top level result");
    INTEXPECT( compiledClass.methods.count,1,@"method count");
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/concatter.o" atomically:YES];
}

+(void)testJitCompileAMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"extension ConcatterTest1 { -concat:a and:b { a, b. }}"];
    compiler.jit = YES;
    [compiler compileMethod:compiledClass.methods.firstObject inClass:compiledClass];
    MPWJittableData *methodData = compiler.codegen.generatedCode;
    ConcatterTest1* concatter=[[ConcatterTest1 new] autorelease];
    NSString* result=nil;
    NSException *didRaise=nil;
    @try {
        result=[concatter concat:@"This is " and:@"working"];
        EXPECTFALSE(true,@"should not get here");
    } @catch ( NSException *e ) {
        didRaise=e;
    }
    EXPECTNOTNIL(didRaise, @"should have raised");
    IDEXPECT(didRaise.name,  NSInvalidArgumentException,@"type of exception");
    [concatter.class addMethod:methodData.bytes forSelector:@selector(concat:and:) types:"@@:@@"];
    result=[concatter concat:@"This is " and:@"working"];
    IDEXPECT(result,@"This is working",@"concatted");
}

+(ConcatterTest1*)compileAndAddSingleMethodExtensionToConcatter:(NSString*)code
{
    STNativeCompiler *compiler = [self compiler];
    compiler.jit = YES;
    MPWClassDefinition * compiledClass = [compiler compile:code];
    MPWScriptedMethod *method = compiledClass.methods.firstObject;
    MPWJittableData *methodData=[compiler compiledCodeForMethod:method inClass:compiledClass];
    ConcatterTest1* concatter=[[ConcatterTest1 new] autorelease];
    [concatter.class addMethod:methodData.bytes forSelector:method.header.selector types:method.header.typeSignature];
    return concatter;
}

+(void)testJitCompileAMethodMoreCompactly
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -concat:a also:b { a, b. }}"];
    IDEXPECT([concatter concat:@"This abbreviated version " also:@"also works"],@"This abbreviated version also works",@"concatted");
}

+(void)testJitCompileNumberObjectLiteral
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -theAnswer { 42. }}"];
    IDEXPECT([concatter theAnswer],@(42),@"the answer");
}

+(void)testJitCompileStringObjectLiteral
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -stringAnswer { 'answer: 42'. }}"];
    IDEXPECT([concatter stringAnswer],@"answer: 42",@"the answer");
}

+(void)testJitCompileNumberArithmetic
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -arithmeticTest { 20 + 2. }}"];
    IDEXPECT([concatter arithmeticTest],@(200),@"the answer");
}

+(void)testCompileNumberArithmeticToMachO
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class ArithmeticTester { -arithmeticTest { 20 + 2. }}"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/arithmetic.o" atomically:YES];
}

+(NSArray*)testSelectors
{
   return @[
       @"testCompileSimpleClassAndMethod",
       @"testCompileMethodWithMultipleArgs",
       @"testJitCompileAMethod",
       @"testJitCompileNumberObjectLiteral",            // moving this test to the end causes tests to crash under Xcode
       @"testJitCompileAMethodMoreCompactly",
//       @"testJitCompileNumberArithmetic",
       @"testCompileNumberArithmeticToMachO",
//       @"testJitCompileStringObjectLiteral",
			];
}

@end
