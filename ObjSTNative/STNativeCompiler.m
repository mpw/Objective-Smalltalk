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
#import "MPWClassScheme.h"

@interface STNativeCompiler()

-(int)generateCodeForExpression:(MPWExpression*)expression;
-(int)generateCodeFor:(MPWExpression*)someExpression;
-(int)generateIdentifierExpression:(MPWIdentifierExpression*)expr;
-(int)generateMessageSend:(MPWMessageExpression*)expr;
-(int)generateLiteralExpression:(MPWLiteralExpression*)expr;
-(int)generateAssignmentExpression:(MPWAssignmentExpression*)expr;
-(int)generateBlockExpression:(MPWBlockExpression*)expr;

-(int)generateLoadClassReference:(NSString*)className;


@property (nonatomic,strong) NSMutableDictionary *variableToRegisterMap;

@property (nonatomic, assign) int localRegisterMin,localRegisterMax,currentLocalRegStack,savedRegisterMax;



@end


@interface MPWScheme(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(MPWIdentifier*)identifier on:(STNativeCompiler*)compiler;

@end


 
@interface MPWExpression(nativeCode)
-(int)generateNativeCodeOn:(STNativeCompiler*)compiler;

@end

@implementation MPWScheme(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(MPWIdentifier*)identifier on:(STNativeCompiler*)compiler
{
    @throw [NSException exceptionWithName:@"unimplemented" reason:@"generating code for identifier not implemented" userInfo:@{}];
}

@end

@implementation MPWClassScheme(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(MPWIdentifier*)identifier on:(STNativeCompiler*)compiler
{
    return [compiler generateLoadClassReference:[identifier stringValue]];
}

@end

@implementation MPWExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateCodeForExpression:self];
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{

}

@end
@implementation MPWStatementList(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    int returnRegister=0;
//    NSLog(@"statements: %@",statements);
    for ( id statement in [self statements] ) {
        returnRegister=[compiler generateCodeFor:statement];
    }
    return returnRegister;
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    for ( id statement in [self statements] ) {
        [statement accumulateBlocks:blocks];
    }
}


@end
@implementation MPWMessageExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateMessageSend:self];
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    [[self receiver] accumulateBlocks:blocks];
    for ( id arg in [self args] ) {
        [arg accumulateBlocks:blocks];
    }
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
    return [compiler generateAssignmentExpression:self];
}


@end

@implementation MPWBlockExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateBlockExpression:self];
}

-(NSString*)name
{
    NSLog(@"name called: %@",[NSThread callStackSymbols]);
    return nil;
}

-(void)accumulateBlocks:(NSMutableArray*)blocks
{
    for ( id statement in [self statementArray] ) {
        [statement accumulateBlocks:blocks];
    }
    [blocks addObject:self];
}


@end


@implementation STNativeCompiler
{
    MPWARMObjectCodeGenerator* codegen;
    MPWMachOWriter *writer;
    MPWMachOClassWriter *classwriter;
    int blockNo;
    int stringLiteralNo;
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
 

-(int)generateLoadClassReference:(NSString*)className
{
    
    NSString *classRefLabel = [writer addClassRefernceForClass:className];
    [codegen addRelocationEntryForSymbol:classRefLabel relativeOffset:0 type:ARM64_RELOC_PAGE21 relative:YES];
    [codegen appendWord32:[codegen adrpToDestReg:0 withPageOffset:0]];
    [codegen addRelocationEntryForSymbol:classRefLabel relativeOffset:0 type:ARM64_RELOC_PAGEOFF12 relative:NO];
    [codegen generateAddDest:0 source:0 immediate:0];
    [codegen loadRegister:0 fromContentsOfAdressInRegister:0];
    return 0;
//    NSAssert1(false,@"don't know how to compile class reference: %@",className);
}

-(int)generateIdentifierExpression:(MPWIdentifierExpression*)expr
{
    NSString *name=[[expr identifier] stringValue];
    NSNumber *registerNumber =  self.variableToRegisterMap[name];
    if ( registerNumber ) {
        return registerNumber.intValue;
    }  else {
        MPWScheme *scheme=[self schemeForName:[expr.identifier schemeName]];
        NSAssert2(scheme != nil, @"unknown scheme %@ identifier %@",[expr.identifier schemeName],expr.identifier);
        return [scheme generateLoadForIdentifier:expr.identifier on:self];
    }
}

-(int)generateBlockExpression:(MPWBlockExpression*)expr
{
    NSAssert1( expr.symbol != nil, @"blockmust have a symbol: %@",expr);
    unsigned int adrp=[codegen adrpToDestReg:0 withPageOffset:0];
    [codegen addRelocationEntryForSymbol:expr.symbol relativeOffset:0 type:ARM64_RELOC_PAGE21 relative:YES];
    [codegen appendWord32:adrp];
    [codegen addRelocationEntryForSymbol:expr.symbol relativeOffset:0 type:ARM64_RELOC_PAGEOFF12 relative:NO];
    [codegen generateAddDest:0 source:0 immediate:0];
    [codegen loadRegister:0 fromContentsOfAdressInRegister:0];
    return 0;
}

-(int)generateStringLiteral:(NSString*)theString intoRegister:(int)regno
{
    if (self.jit) {
        [codegen loadRegister:regno withConstantAdress:theString];
        return regno;
    } else {
        stringLiteralNo++;
        NSString *literalSymbol=[NSString stringWithFormat:@"_CFSTR_L%d",stringLiteralNo];
        [writer writeNSStringLiteral:theString label:literalSymbol];
        [codegen addRelocationEntryForSymbol:literalSymbol relativeOffset:0 type:ARM64_RELOC_PAGE21 relative:YES];
        [codegen appendWord32:[codegen adrpToDestReg:regno withPageOffset:0]];
        [codegen addRelocationEntryForSymbol:literalSymbol relativeOffset:0 type:ARM64_RELOC_PAGEOFF12 relative:NO];
        [codegen generateAddDest:regno source:regno immediate:0];

    }
    return regno;
}

-(int)generateStringLiteral:(NSString*)theString
{
    return [self generateStringLiteral:theString intoRegister:0];
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
    NSLog(@"lhs: %@ / %@",lhs.class,lhs);
    NSString *lhsName = [lhs name];
    NSLog(@"got the name: %@",lhsName);
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


-(void)saveLocalRegisters:(NSArray*)localVars andMoveArgs:(NSArray*)args
{
    int numLocalVars = (int)localVars.count;
    int totalArguments=(int)args.count;
    self.currentLocalRegStack+=10;
    [self saveRegisters];
    
    self.currentLocalRegStack=self.localRegisterMin+totalArguments;
    
    [self moveRegister:0 toRegister:self.localRegisterMin];
    for (int i=0;i<totalArguments;i++) {
        [self moveRegister:i toRegister:self.localRegisterMin+i];
        self.variableToRegisterMap[args[i]]=@(self.localRegisterMin+i);
    }
    //--- save registers needed
    for (int i=0;i<numLocalVars;i++) {
        [codegen clearRegister:self.localRegisterMin+i+totalArguments];
        self.variableToRegisterMap[localVars[i]]=@(self.localRegisterMin+i+totalArguments);
    }
}

-(void)saveLocalRegistersAndMoveArgs:(MPWScriptedMethod*)method
{
    NSArray *localVars = [method localVars];
    NSMutableArray *arguments =[[@[ @"self" , @"_cmd"] mutableCopy] autorelease];
    for (int i=0,max=method.methodHeader.numArguments;i<max;i++) {
        [arguments addObject:[method.methodHeader argumentNameAtIndex:i]];
    }
    [self saveLocalRegisters:localVars andMoveArgs:arguments];
}

-(void)restoreLocalRegisters
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
    [self restoreLocalRegisters];
    return returnRegister;
}

-(NSString*)compileMethod:(MPWScriptedMethod*)method inClass:(MPWClassDefinition*)aClass
{
    NSArray *blocks = [self findBlocksInMethod:method];
    for ( MPWBlockExpression *block in blocks ) {
        NSString *blockSymbol = [self compileBlock:block];
        block.symbol = blockSymbol;
    }
    NSString *symbol = [NSString stringWithFormat:@"-[%@ %@]",aClass.name,method.methodName];
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
    //--- retrieve all the blocks and generate them first
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
    [writer addClassRefernceForClass:aClass.name];
}

-(void)compileAndWriteClass:(MPWClassDefinition*)aClass
{
    [self compileClass:aClass];
    [writer writeFile];
}

-(void)compileMainCallingClass:(NSString*)aClassName
{
    NSString *symbol = @"_main";
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
    [codegen generateFunctionNamed:symbol body:^(MPWARMObjectCodeGenerator * _Nonnull gen) {
        [self generateStringLiteral:aClassName intoRegister:2];
//        [codegen loadRegister:2 fromContentsOfAdressInRegister:2];
        [codegen generateCallToExternalFunctionNamed:@"_runSTMain"];
        [codegen generateMoveConstant:0 to:0];
    }];
}


-(NSString*)compileBlock:(MPWBlockExpression*)aBlock
{
    blockNo++;
    NSString *symbol = [NSString stringWithFormat:@"_block_invoke_%d",blockNo];
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
    //--- retrieve all the blocks and generate them first
    [codegen generateFunctionNamed:symbol body:^(MPWARMObjectCodeGenerator * _Nonnull gen) {
        
        int returnRegister=0;
        NSArray *arguments=[aBlock arguments];
        arguments=[@[@"_thisBlock"] arrayByAddingObjectsFromArray:arguments];
        [self saveLocalRegisters:@[] andMoveArgs:arguments];
        id statements = [aBlock statements];
        if ( [statements respondsToSelector:@selector(statements)]) {
            statements=[statements statements];
        }
        if ( [statements respondsToSelector:@selector(count)]) {
            for ( id statement in statements) {
                returnRegister = [statement generateNativeCodeOn:self];
            }
        } else {
            returnRegister = [statements generateNativeCodeOn:self];
        }
        [self moveRegister:returnRegister toRegister:0];
        [self restoreLocalRegisters];
    }];
    NSString *blockSymbol = [NSString stringWithFormat:@"_theBlock_l%d",blockNo];
    [writer writeBlockLiteralWithCodeAtSymbol:symbol blockSymbol:blockSymbol signature:@"i" global:YES];
    return blockSymbol;
}

-(NSData*)compileClassToMachoO:(MPWClassDefinition*)aClass
{
    [self compileAndWriteClass:aClass];
    return (NSData*)[writer target];
}

-(NSData*)compileBlockToMachoO:(MPWBlockExpression*)aBlock
{
    [self compileBlock:aBlock];
    [writer addTextSectionData:[codegen target]];
    [writer writeFile];
    return (NSData*)[writer target];
}

-(NSArray*)findBlocksInMethod:(MPWScriptedMethod*)aMethod
{
    NSMutableArray *blocks=[NSMutableArray array];
    [aMethod.methodBody accumulateBlocks:blocks];
    return blocks;
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

+(void)testCompileSimpleClassWithTwoMethods
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@" class TestClass2Methods : NSObject {  -<int>hashPlus100 { self hash + 100. } -<int>hashPlus200  { self hash + 200. }}"];
    IDEXPECT( compiledClass.name, @"TestClass2Methods", @"top level result");
    INTEXPECT( compiledClass.methods.count,2,@"method count");
    INTEXPECT( compiledClass.classMethods.count,0,@"class method count");
    NSData *macho=[compiler compileClassToMachoO:compiledClass];
    [macho writeToFile:@"/tmp/testclass2methods-from-source.o" atomically:YES];
    MPWMachOReader *reader = [MPWMachOReader readerWithData:macho];
    EXPECTTRUE(reader.isHeaderValid, @"got a macho");
    INTEXPECT([reader classReaders].count,1,@"number of classes" );
    MPWMachOClassReader *classReader = [reader classReaders].firstObject;
    IDEXPECT(classReader.nameOfClass, @"TestClass2Methods", @"name of class");
    IDEXPECT(classReader.superclassPointer.targetName, @"_OBJC_CLASS_$_NSObject", @"symbol for superclass");
    INTEXPECT(classReader.numberOfMethods, 2,@"number of methods");
    IDEXPECT([classReader methodNameAt:0].targetPointer.stringValue,@"hashPlus100",@"name of method");
    IDEXPECT([classReader methodNameAt:1].targetPointer.stringValue,@"hashPlus200",@"name of method");
    IDEXPECT([classReader methodTypesAt:0].targetPointer.stringValue,@"l@:",@"type of method");
    IDEXPECT([classReader methodCodeAt:0].targetName,@"-[TestClass2Methods hashPlus100]",@"symbol for method code");
    IDEXPECT([classReader methodCodeAt:1].targetName,@"-[TestClass2Methods hashPlus200]",@"symbol for method code");
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
    ConcatterTest1 *concatter=[self compileAndAddSingleMethodExtensionToConcatter:@"extension ConcatterTest1 { -stringAnswer { 'abcd'.  'answer: 42'. }}"];
    IDEXPECT([concatter stringAnswer],@"answer: 42",@"the answer");
}

+(void)testMachOCompileStringObjectLiteral
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition * compiledClass = [compiler compile:@"class StringTest { -stringAnswer { 'answer: 42'. }}"];
    NSData *d=[compiler compileClassToMachoO:compiledClass];
    [d writeToFile:@"/tmp/stringLiteral.o" atomically:YES];

    MPWMachOReader *reader=[MPWMachOReader readerWithData:d];
    MPWMachOInSectionPointer *s=[reader pointerForSymbolAt:[reader indexOfSymbolNamed:@"_CFSTR_L1"]];
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

+(void)testMachOCompileBlock
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ 3 }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockFromST.o" atomically:YES];
}

+(void)testMachOCompileBlockWithArg
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ :a | a + 3. }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockWithArg.o" atomically:YES];
}

+(void)testMachOCompileAndRunBlockWithArg
{
    STNativeCompiler *compiler = [self compiler];
    MPWBlockExpression * compiledBlock = [compiler compile:@"{ :a | a + 3. }"];
    [[compiler compileBlockToMachoO:compiledBlock] writeToFile:@"/tmp/blockWithArgToLink.o" atomically:YES];
    [[self frameworkResource:@"use_st_block" category:@"mfile"] writeToFile:@"/tmp/use_st_block.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -O  -Wall -o use_st_block use_st_block.m blockWithArgToLink.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_st_block");
    INTEXPECT(runSucess,0,@"run worked");

}

+(void)testJITCompileBlockWithArg
{
    STNativeCompiler *compiler = [self jitCompiler];
    MPWBlockInvocable * compiledBlock = [compiler evaluateScriptString:@"{ :a | a + 3. }"];
    IDEXPECT( [compiledBlock value:@(12)],@(15),@"jitted block");
}

+(void)testFindBlocksInMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition *theClass = [compiler compile:@"class Hi { -tester:cond { cond ifTrue: { 'trueBlock'. } ifFalse:{ 'falseBlock'. }. } }"];
    MPWScriptedMethod *firstMethod = [[theClass methods] firstObject];
    IDEXPECT( [firstMethod methodName],@"tester:", @"method name");
    NSArray *blocks = [compiler findBlocksInMethod:firstMethod];
    INTEXPECT(blocks.count, 2,@"number of blocks in method");
    MPWBlockExpression *trueBlock = blocks.firstObject;
    MPWBlockExpression *falseBlock = blocks.lastObject;
    MPWLiteralExpression *trueLiteral = [[trueBlock statementArray] firstObject];
    MPWLiteralExpression *falseLiteral = [[falseBlock statementArray] lastObject];
    IDEXPECT( trueLiteral.theLiteral, @"trueBlock",@"true block literal");
    IDEXPECT( falseLiteral.theLiteral, @"falseBlock",@"false block literal");
}

+(void)testGenerateCodeForBlocksInMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition *theClass = [compiler compile:@"class TestClassIfTrueIfFalse { -tester:cond { cond ifTrue: { 3. } ifFalse:{ 2. }. } }"];
    [[compiler compileClassToMachoO:theClass] writeToFile:@"/tmp/classWithIfTrueIfFalse.o" atomically:YES];
    
    
    [[self frameworkResource:@"use_class_with_if" category:@"mfile"] writeToFile:@"/tmp/use_class_with_if.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -O  -Wall -o use_class_with_if use_class_with_if.m classWithIfTrueIfFalse.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_class_with_if");
    INTEXPECT(runSucess,0,@"run worked");
}

+(void)testGenerateCodeForClassReference
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition *theClass = [compiler compile:@"class TestClassWithClassRef { -tester { class:NSObject new. } }"];
    [[compiler compileClassToMachoO:theClass] writeToFile:@"/tmp/classThatCreatesNSObjects.o" atomically:YES];
    
    
    [[self frameworkResource:@"use_class_that_creates_nsobject" category:@"mfile"] writeToFile:@"/tmp/use_class_that_creates_nsobject.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -O  -Wall -o use_class_that_creates_nsobject use_class_that_creates_nsobject.m classThatCreatesNSObjects.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_class_that_creates_nsobject");
    INTEXPECT(runSucess,0,@"run worked");
}

+(void)testGenerateMainThatCallsClassMethod
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition *theClass = [compiler compile:@"class TestHelloWorld : STProcess { -main:args { class:MPWByteStream Stdout println:'Hello World from auto-generated main'. } }"];
    [compiler compileMainCallingClass:@"TestHelloWorld"];
    [compiler compileClass:theClass];
    [compiler.writer writeFile];
    [(NSData*)[compiler.writer target] writeToFile:@"/tmp/selfContainedHelloWorld.o" atomically:YES];
    int compileSucess = system("cd /tmp; cc -O  -Wall -o selfContainedHelloWorld selfContainedHelloWorld.o  -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./selfContainedHelloWorld");
    INTEXPECT(runSucess,0,@"run worked");

}

+(void)testTwoStringsInMachO
{
    STNativeCompiler *compiler = [self compiler];
    MPWClassDefinition *theClass = [compiler compile:@"class TestClassTwoStrings { -method1 { 'Hello World!'.} -method2 { '2nd string'. } }"];
    [[compiler compileClassToMachoO:theClass] writeToFile:@"/tmp/classWithTwoStrings.o" atomically:YES];
    
    
    [[self frameworkResource:@"use_class_with_two_strings" category:@"mfile"] writeToFile:@"/tmp/use_class_with_two_strings.m" atomically:YES];
    int compileSucess = system("cd /tmp; cc -O  -Wall -o use_class_with_two_strings use_class_with_two_strings.m classWithTwoStrings.o -F/Library/Frameworks -framework ObjectiveSmalltalk   -framework MPWFoundation -framework Foundation");
    INTEXPECT(compileSucess,0,@"compile worked");
    int runSucess = system("cd /tmp; ./use_class_with_two_strings");
    INTEXPECT(runSucess,0,@"run worked");
}


+(NSArray*)testSelectors
{
   return @[
       @"testCompileSimpleClassAndMethod",
       @"testCompileMethodWithMultipleArgs",
       @"testCompileSimpleClassWithTwoMethods",
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
       @"testMachOCompileBlock",
       @"testMachOCompileBlockWithArg",
       @"testMachOCompileAndRunBlockWithArg",
       @"testJITCompileBlockWithArg",
       @"testFindBlocksInMethod",
       @"testGenerateCodeForBlocksInMethod",
       @"testGenerateCodeForClassReference",
       @"testGenerateMainThatCallsClassMethod",
       @"testTwoStringsInMachO",
			];
}

@end

