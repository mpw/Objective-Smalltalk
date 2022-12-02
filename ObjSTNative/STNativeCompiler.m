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
#import "MPWJittableData.h"
#import <mach-o/arm64/reloc.h>


@interface STNativeCompiler()

-(int)generateCodeForExpression:(MPWExpression*)expression;
-(int)generateCodeFor:(MPWExpression*)someExpression;
-(int)generateIdentifierExpression:(MPWIdentifierExpression*)expr;
-(int)generateMessageSend:(MPWMessageExpression*)expr;
-(int)generateLiteralExpression:(MPWLiteralExpression*)expr;
-(int)generateAssignmentExpression:(MPWAssignmentExpression*)expr;

@property (nonatomic,strong) NSMutableDictionary *variableToRegisterMap;

@property (nonatomic, assign) int localRegisterMin,localRegisterMax,currentLocalRegStack,savedRegisterMax;



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

@implementation STVariableDefinition(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return 0;
}

@end

@implementation MPWAssignmentExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    [compiler generateAssignmentExpression:self];
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

+(instancetype)jitCompiler
{
    STNativeCompiler *compiler=[self compiler];
    compiler.jit=true;
    return compiler;
}

-(instancetype)init
{
    self=[super init];
    if ( self ) {
        self.writer = [MPWMachOWriter stream];
        self.classwriter = [MPWMachOClassWriter writerWithWriter:writer];
        self.codegen = [MPWARMObjectCodeGenerator stream];
        
        self.localRegisterMin = 19;     // ARM min saved register
        self.localRegisterMax = 29;     // ARM min saved register
        self.currentLocalRegStack = self.localRegisterMin;
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

-(int)generateStringLiteral:(NSString*)theString
{
    if (self.jit) {
        [codegen loadRegister:0 withConstantAdress:theString];
        return 0;
    } else {
        NSString *literalSymbol=@"_CFSTR_L_";
        [writer writeNSStringLiteral:theString label:literalSymbol];
        [codegen addRelocationEntryForSymbol:literalSymbol relativeOffset:0 type:ARM64_RELOC_PAGE21 relative:YES];
        [codegen appendWord32:[codegen adrpToDestReg:0 withPageOffset:0]];
        [codegen addRelocationEntryForSymbol:literalSymbol relativeOffset:0 type:ARM64_RELOC_PAGEOFF12 relative:NO];
        [codegen generateAddDest:0 source:0 immediate:0];

    }
    return 0;
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
        return [self generateStringLiteral:theLiteral];
    }
    [NSException raise:@"unsupported" format:@"don't know how to compile literal: %@  (%@):",theLiteral,[theLiteral class]];
    return 0;
}

-(int)generateAssignmentExpression:(MPWAssignmentExpression*)expr
{
    MPWExpression *rhs = [expr rhs];
    MPWIdentifierExpression *lhs = [expr lhs];
    int registerForRHS = [self generateCodeFor:rhs];
    NSString *lhsName = [lhs name];
    NSNumber *lhsRegisterNumber = self.variableToRegisterMap[lhsName];
    NSAssert1( lhsRegisterNumber, @"Don't have a variable named '%@'",lhsName);
    [self moveRegister:registerForRHS toRegister:lhsRegisterNumber.intValue];
}

-(int)allocateRegister
{
    int theRegister = self.currentLocalRegStack;
    self.currentLocalRegStack++;
    if ( self.currentLocalRegStack <= self.localRegisterMax) {
        return theRegister;
    } else {
        @throw [NSException exceptionWithName:@"overflow" reason:@"out of registers" userInfo:nil];
    }
}


-(int)generateCodeForExpression:(MPWExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't yet compile code for %@/%@",expression.class,expression];
    return 0;
}

-(void)moveRegister:(int)source toRegister:(int)dest
{
    if (source != dest) {
//        NSLog(@"%d != %d, generate the move via %@",source,dest,codegen);
        [codegen generateMoveRegisterFrom:source to:dest];
    }
}


-(int)generateMessageSend:(MPWMessageExpression*)expr
{
    NSString *selectorString = NSStringFromSelector(expr.selector);

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
        int currentRegs = self.currentLocalRegStack;
        NSMutableArray *toEval = [NSMutableArray arrayWithObject:expr.receiver];
        [toEval addObjectsFromArray:expr.args];
        int numArgs = toEval.count;
        int argRegisters[numArgs];
//        NSLog(@"%@ receiver + args: %@",NSStringFromSelector(expr.selector), toEval);
        for (int i=0;i<numArgs;i++) {
            if ( [toEval[i] isKindOfClass:[MPWMessageExpression class]] ||
                [toEval[i] isKindOfClass:[MPWLiteralExpression class]]
                ) {
                argRegisters[i]=[self allocateRegister];
            } else {
                argRegisters[i]=0;
            }
        }
        [self saveRegisters];
        
        // evaluate any message expressions

//        NSLog(@"first pass, nested messages for %@",NSStringFromSelector(expr.selector));
        for (int i=0;i<numArgs;i++) {
            if ( argRegisters[i] != 0) {            // this is a nested message/function expression, need to evaluate now and stash result
                int evaluatedRegister = [self generateCodeFor:toEval[i]];
//                NSLog(@"evaluated[%d] %@ and returned in %d",i,toEval[i],evaluatedRegister);;
//                NSLog(@"evaluated[%d] stash in %d",i,argRegisters[i]);;
                [self moveRegister:evaluatedRegister toRegister:argRegisters[i]];
            }
        }
        
        // now move everything into argument passing registers
        
//        NSLog(@"second pass, non-messages for %@",NSStringFromSelector(expr.selector));
       for (int i=numArgs-1;i>=0;i--) {
            int evaluatedRegister;
            if ( argRegisters[i] == 0) {    // evaluate now, wasn't evaluated before
                evaluatedRegister = [self generateCodeFor:toEval[i]];
//                NSLog(@"evaluated[%d] %@ result in register %d",i,toEval[i],evaluatedRegister);
            } else {                        // was evaluated before fetch the register the value is stashed in
                evaluatedRegister = argRegisters[i];
//                NSLog(@"previously evaluated[%d] result in register %d",i,evaluatedRegister);
            }
            [self moveRegister:evaluatedRegister toRegister:i >= 1 ? i+1 : i];
        }

        if ( self.jit ) {
            [codegen generateJittedMessageSendToSelector:selectorString];
        } else {
            [codegen generateMessageSendToSelector:selectorString];
        }
        
        self.currentLocalRegStack=currentRegs;
        return 0;
    }
    return 0;
}

-(int)generateCodeFor:(MPWExpression*)someExpression
{
    return [someExpression generateNativeCodeOn:self];
}

-(void)saveRegisters
{
    if ( self.currentLocalRegStack > self.savedRegisterMax) {
        int numRegister=self.currentLocalRegStack - self.savedRegisterMax;
        int numPairs = (numRegister+1)/2;
        for (int i=0,regno=self.savedRegisterMax;i<numPairs;i++,regno+=2) {
            int relativeOffset=regno - self.localRegisterMin;
            [codegen  generateSaveRegister:regno andRegister:regno+1 relativeToRegister:31 offset:relativeOffset*8 rewrite:NO pre:NO];
        }
        self.savedRegisterMax=self.currentLocalRegStack;
    }
}


-(void)saveLocalRegistersAndMoveArgs:(MPWScriptedMethod*)method
{
    NSArray *localVars = [method localVars];
    int numLocalVars = (int)localVars.count;
    int totalArguments=method.methodHeader.numArguments+2;
//     self.currentLocalRegStack+=totalArguments;
    self.currentLocalRegStack+=10;
    [self saveRegisters];
    
    self.currentLocalRegStack=self.localRegisterMin+totalArguments;

    self.variableToRegisterMap[@"self"]=@(self.localRegisterMin);
    [self moveRegister:0 toRegister:self.localRegisterMin];
    for (int i=2;i<totalArguments;i++) {
        [self moveRegister:i toRegister:self.localRegisterMin+i];
        self.variableToRegisterMap[[method.methodHeader argumentNameAtIndex:i-2]]=@(self.localRegisterMin+i);
    }
    //--- save registers needed 
    for (int i=0;i<numLocalVars;i++) {
        [codegen clearRegister:self.localRegisterMin+i+totalArguments];
        self.variableToRegisterMap[localVars[i]]=@(self.localRegisterMin+i+totalArguments);
    }
}

-(void)restoreLocalRegisters:(MPWScriptedMethod*)method
{
    int totalToRestore=self.savedRegisterMax - self.localRegisterMin;
    int numPairs = (totalToRestore+1)/2;
    for (int i=0,regno=self.localRegisterMin;i<numPairs;i++,regno+=2) {
        [codegen  generateLoadRegister:regno andRegister:regno+1 relativeToRegister:31 offset:i*16 rewrite:NO pre:NO];
    }
}

-(int)writeMethodBody:(MPWScriptedMethod*)method
{
    self.currentLocalRegStack=self.localRegisterMin;
    self.savedRegisterMax=self.localRegisterMin;

    [self saveLocalRegistersAndMoveArgs:method];
    int returnRegister =  [method.methodBody generateNativeCodeOn:self];
    [self restoreLocalRegisters:method];
    return returnRegister;
}

-(NSString*)compileMethod:(MPWScriptedMethod*)method inClass:(MPWClassDefinition*)aClass
{
    NSString *symbol = [NSString stringWithFormat:@"-[%@ %@]",aClass.name,method.methodName];
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
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

-(void)compileAndAddMethod:(MPWScriptedMethod*)method forClassDefinition:(MPWClassDefinition*)compiledClass
{
    MPWJittableData *methodData=[self compiledCodeForMethod:method inClass:compiledClass];
    Class existingClass=NSClassFromString(compiledClass.name);
    NSAssert1(existingClass!=nil , @"Class not found: %@", compiledClass.name);
    [existingClass addMethod:methodData.bytes forSelector:method.header.selector types:method.header.typeSignature];
}

-(void)compileAndAddMethodsForClassDefinition:(MPWClassDefinition*)aClass
{
    for ( MPWScriptedMethod* method in aClass.methods) {
        [self compileAndAddMethod:method forClassDefinition:aClass];
    }
}

-(void)defineMethodsForClassDefinition:(MPWClassDefinition*)classDefinition
{
    if (self.jit) {
        [self compileAndAddMethodsForClassDefinition:classDefinition];
    } else {
        [self compileMethodsForClass:classDefinition];
    }
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
#import "Mach_O_Structs.h"

@interface ConcatterTest1: NSObject
@end
@interface ConcatterTest1(dynamic)
-concat:a and:b;
-concat:a also:b;
-(NSNumber*)someConstantNumbersAdded;
-(NSString*)stringAnswer;
-add:a to:b to:c;
-theAnswer;
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
    STNativeCompiler *compiler = [self jitCompiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"extension ConcatterTest1 { -concat:a and:b { a, b. }}"];
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
    STNativeCompiler *compiler = [self jitCompiler];
    MPWClassDefinition *compiledClass = [compiler compile:code];
    [compiler compileAndAddMethodsForClassDefinition:compiledClass];
    return [[ConcatterTest1 new] autorelease];
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

+(void)testMachOCompileStringObjectLiteral
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class StringTest { -stringAnswer { 'answer: 42'. }}"];
    NSData *d=[compiler compileClassToMachoO:compiledClass];
    [d writeToFile:@"/tmp/stringLiteral.o" atomically:YES];
    
    MPWMachOReader *reader=[MPWMachOReader readerWithData:d];
    MPWMachOInSectionPointer *s=[reader pointerForSymbolAt:[reader indexOfSymbolNamed:@"_CFSTR_L_"]];
    EXPECTNOTNIL(s, @" pointer");
    Mach_O_NSString *str_read=(Mach_O_NSString*)[s bytes];
    IDEXPECT([[s relocationPointer] targetName],@"___CFConstantStringClassReference",@"class");
    INTEXPECT( str_read->length,10,@"length");
    INTEXPECT( str_read->flags, 1992, @"flags");

    long offset=((void*)&str_read->cstring) - (void*)str_read;
    MPWMachOInSectionPointer *contentPtr = [[s relocationPointerAtOffset:offset] targetPointer];
    IDEXPECT( contentPtr.stringValue,@"answer: 42",@"contents");

    
    
}

+(void)testJitCompileNumberArithmetic
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -add:a to:b to:c { a+b+c. }}"];
    IDEXPECT([concatter add:@(100) to:@(10) to:@(3)],@(113),@"the answer");
}

+(void)testJitCompileConstantNumberArithmeticSequence
{
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -someConstantNumbersAdded { 100+30 + 5  * 2 * 2. }}"];
    id expectedAnswer = @(540);
    id computedAnswer = [concatter someConstantNumbersAdded];
    IDEXPECT(computedAnswer,expectedAnswer,@"the answer");
}

+(void)testCompileConstantNumberArithmeticToMachO
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class ArithmeticTester { -someConstantNumbersAdded { 100+30+7. }}"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/constantArithmetic.o" atomically:YES];
}

+(void)testCompileNumberArithmeticToMachO
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class ArithmeticTester { -add:a to:b to:c { a+b+c. }}"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/arithmetic.o" atomically:YES];
}

+(void)testMachOCompileSimpleFilter
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"filter Upcaser |{ ^object stringValue uppercaseString. }"];
    [[compiler compileClassToMachoO:compiledClass] writeToFile:@"/tmp/upcasefilter.o" atomically:YES];
}

+(void)testJitCompileFilter
{
    STNativeCompiler *compiler = [self jitCompiler];
    Class testClass1 = [compiler evaluateScriptString:@"filter TestDowncaser |{ ^object lowercaseString. }"];
    MPWFilter *filter = [testClass1 stream];
    [filter writeObject:@"Some Upper CASE string Data"];
    IDEXPECT([(NSArray*)[filter target] firstObject],@"some upper case string data",@"Filter result (should be lowercase)");
    
}

+(void)testJitCompileMethodWithLocalVariables
{
    STNativeCompiler *compiler = [self jitCompiler];
    Class testClass1 = [compiler evaluateScriptString:@"filter TestLocalVarFilter |{ var a. a := object uppercaseString. ^a. ^object. }"];
    MPWFilter *filter = [testClass1 stream];
    NSString *testData = @"Some Upper CASE string Data";
    [filter writeObject:testData];
    IDEXPECT([(NSArray*)[filter target] firstObject],@"SOME UPPER CASE STRING DATA",@"Filter result (should be uppercase)");
    IDEXPECT([(NSArray*)[filter target] lastObject],testData,@"second filter result");
}

+(void)testJitCompileBlock
{
//    EXPECTTRUE(false,@"implemented");
}


+(NSArray*)testSelectors
{
   return @[
       @"testCompileSimpleClassAndMethod",
       @"testCompileMethodWithMultipleArgs",
       @"testJitCompileAMethod",
       @"testJitCompileNumberObjectLiteral",
       @"testJitCompileAMethodMoreCompactly",
       @"testJitCompileNumberArithmetic",
       @"testJitCompileConstantNumberArithmeticSequence",
       @"testCompileConstantNumberArithmeticToMachO",
       @"testCompileNumberArithmeticToMachO",
       @"testMachOCompileSimpleFilter",
       @"testJitCompileStringObjectLiteral",
       @"testMachOCompileStringObjectLiteral",
       @"testJitCompileFilter",
       @"testJitCompileMethodWithLocalVariables",
//       @"testJitCompileBlock",
			];
}

@end
