//
//  STNativeCompiler.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.10.22.
//

#import "STNativeCompiler.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import "MPWMachOWriter.h"
#import "STObjectCodeGeneratorARM.h"
#import "MPWMachOClassWriter.h"
#import <ObjectiveSmalltalk/MPWMessageExpression.h>
#import <ObjectiveSmalltalk/MPWLiteralExpression.h>
#import <ObjectiveSmalltalk/MPWLiteralArrayExpression.h>
#import <ObjectiveSmalltalk/MPWLiteralDictionaryExpression.h>
#import <ObjectiveSmalltalk/STIdentifierExpression.h>
#import <ObjectiveSmalltalk/STSubscriptExpression.h>
#import "STJittableData.h"
#import <mach-o/arm64/reloc.h>
#import "MPWClassScheme.h"
#import "STIdentifier.h"
#import "STConnectionDefiner.h"
#import "STMethodSymbols.h"
#import "STNativeJitCompiler.h"

@interface STNativeCompiler()

-(int)generateCodeForExpression:(STExpression*)expression;
-(int)generateCodeFor:(STExpression*)someExpression;
-(int)generateIdentifierExpression:(STIdentifierExpression*)expr;
-(int)generateMessageSendOf:(NSString*)selectorString to:receiver with:args;
-(int)generateMessageSend:(MPWMessageExpression*)expr;
-(int)generateLiteralExpression:(MPWLiteralExpression*)expr;
-(int)generateAssignmentExpression:(MPWAssignmentExpression*)expr;
-(int)generateBlockExpression:(MPWBlockExpression*)expr;
-(int)generateLiteralArrayExpression:(MPWLiteralArrayExpression*)expr;
-(int)generateLoadClassReference:(NSString*)className;
-(int)generateConnectionFrom:(id)left to:(id)right;
-(int)generateLoadIdentifier:(NSString*)identifierName withScheme:(NSString*)scheme;


@property (nonatomic,strong) NSMutableDictionary *variableToRegisterMap;
@property (nonatomic, assign) int localRegisterMin,localRegisterMax,currentLocalRegStack,savedRegisterMax;

@property (nonatomic, assign) BOOL forceStackBlocks;
@property (nonatomic, assign) int currentBlockStackOffset;
@property (nonatomic, strong) MPWBlockExpression *currentBlock;

@end


@interface MPWScheme(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(STIdentifier*)identifier on:(STNativeCompiler*)compiler;

@end


 
@interface STExpression(nativeCode)
-(int)generateNativeCodeOn:(STNativeCompiler*)compiler;

@end

@implementation MPWAbstractStore(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(STIdentifier*)identifier on:(STNativeCompiler*)compiler
{
    return [compiler generateLoadIdentifier:identifier.path withScheme:identifier.schemeName];
//    NSString *msg=[NSString stringWithFormat:@"generating code for identifier '%@' scheme: '%@' not implemented",
//                   identifier.path,identifier.schemeName];
//    @throw [NSException exceptionWithName:@"unimplemented" reason:msg
//                                 userInfo:@{@"identifier": identifier }];
}

@end

@implementation MPWClassScheme(nativeCodeGenertion)

-(int)generateLoadForIdentifier:(STIdentifier*)identifier on:(STNativeCompiler*)compiler
{
    return [compiler generateLoadClassReference:[identifier stringValue]];
}

@end

@implementation STConnectionDefiner(nativeCodeGenertion)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateConnectionFrom:[self lhs] to:[self rhs]];
}

@end

@implementation STExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateCodeForExpression:self];
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

@end


@implementation MPWMessageExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    NSLog(@"generate native code for %@",self);
    return [compiler generateMessageSend:self];
}


@end

@implementation STIdentifierExpression(nativeCode)

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

@implementation STSubscriptExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateMessageSendOf:@"at:" to:self.receiver with:@[ self.subscript]];
}

@end

@implementation MPWLiteralArrayExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateLiteralArrayExpression:self];
}

@end

@implementation MPWLiteralDictionaryExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateLiteralDictionaryExpression:self];
}

@end

@implementation MPWBlockExpression(nativeCode)

-(int)generateNativeCodeOn:(STNativeCompiler*)compiler
{
    return [compiler generateBlockExpression:self];
}

-(NSString*)name
{
    NSLog(@"-[MPWBlockExpression name] called: %@",[NSThread callStackSymbols]);
    return nil;
}


@end


@implementation STNativeCompiler
{
    STObjectCodeGeneratorARM* codegen;
    MPWMachOWriter *writer;
    MPWMachOClassWriter *classwriter;
    int blockNo;
    int stringLiteralNo;
}

objectAccessor(STObjectCodeGeneratorARM*, codegen, setCodegen)
objectAccessor(MPWMachOWriter*, writer, setWriter)
objectAccessor(MPWMachOClassWriter*, classwriter, setClasswriter)

+(instancetype)stackBlockCompiler {
    STNativeCompiler *stackBlockCompiler = [self compiler];
    stackBlockCompiler.forceStackBlocks = true;
    return stackBlockCompiler;
}


+(instancetype)jitCompiler
{
    STNativeCompiler *compiler=[STNativeJitCompiler compiler];
 //   compiler.jit=true;
    return compiler;
}

-createObjectFileWriter
{
    return nil;   // redefined in category to return MachO-writer -> fix
}

-createClassWriter
{
    return nil;   // redefined in category to return MachO-class-writer  -> fix
}

-(instancetype)init
{
    self=[super init];
    if ( self ) {
        self.writer = [self createObjectFileWriter];
        self.classwriter = [self createClassWriter];
        self.codegen = [STObjectCodeGeneratorARM stream];
        
        self.localRegisterMin = 19;     // ARM min saved register
        self.localRegisterMax = 29;     // ARM min saved register
        self.currentLocalRegStack = self.localRegisterMin;
        codegen.symbolWriter = writer;
        codegen.relocationWriter = writer.textSectionWriter;
    }
    return self;
}

-(int)registerForLocalVar:(NSString*)name
{
    return [self.variableToRegisterMap[name] intValue];     // local registers aren't 0, so 0 is an ok sentinel
}
 
-(int)generateIdentifierExpression:(STIdentifierExpression*)expr
{
    NSString *name=[[expr identifier] stringValue];
    int registerNumber =  [self registerForLocalVar:name];
    if ( registerNumber ) {
        return registerNumber;
    }  else if ( self.currentBlock && self.currentBlock.capturedVariableOffets[name] )  {
        int offset = [self.currentBlock.capturedVariableOffets[name] intValue];
        int blockRegister = [self registerForLocalVar:@"_thisBlock"];
        NSAssert( blockRegister , @"have _thisBlock");
        
        [codegen loadRegister:0 fromContentsOfAdressInRegister:blockRegister offset:offset];
        return 0;
    }  else {
        NSString *schemeName = [expr.identifier schemeName];
        if ( schemeName == nil || schemeName.length == 0 ) {
            NSLog(@"can't find identifier '%@' in local vars %@ or captured vars: %@",name,[self localVars],self.currentBlock.capturedVariableOffets);
            NSAssert1(schemeName != nil,@"identifier %@ not found",name);
        }
        MPWScheme *scheme=[self schemeForName:[expr.identifier schemeName]];
        if ( schemeName == nil || schemeName.length == 0 ) {
            NSLog(@"can't find scheme '%@' for identifier: %@",schemeName,name);
            NSAssert2(schemeName != nil,@"scheme %@ for identifier %@ not found",schemeName,name);
        }
        return [scheme generateLoadForIdentifier:expr.identifier on:self];
    }
}

-(int)generateLoadSymbolicAddress:(NSString*)symbol intoRegister:(int)regno
{
    unsigned int adrp=[codegen adrpToDestReg:regno withPageOffset:0];
    [codegen addRelocationEntryForSymbol:symbol relativeOffset:0 type:ARM64_RELOC_PAGE21 relative:YES];
    [codegen appendWord32:adrp];
    [codegen addRelocationEntryForSymbol:symbol relativeOffset:0 type:ARM64_RELOC_PAGEOFF12 relative:NO];
    [codegen generateAddDest:regno source:regno immediate:0];
    return regno;
}

-(int)generateConnectionFrom:(id)left to:(id)right
{
    int lhs_register = [left generateNativeCodeOn:self];
    // probably need to stash lhs register somewhere
    int rhs_register = [right generateNativeCodeOn:self];
    [self moveRegister:rhs_register toRegister:1];
    [self moveRegister:lhs_register toRegister:0];
    
    [codegen generateCallToExternalFunctionNamed:@"_st_connect_components"];
    return 0;
}

-(int)generateLoadIdentifier:(NSString*)identifierName withScheme:(NSString*)scheme
{
    int nameRegister = [self generateStringLiteral:identifierName intoRegister:1];
    int schemeRegister = [self generateStringLiteral:scheme intoRegister:0];
    [self moveRegister:nameRegister toRegister:1];
    [self moveRegister:schemeRegister toRegister:0];
    
    [codegen generateCallToExternalFunctionNamed:@"_st_scheme_at"];
    return 0;
}

-(int)generateStoreObjectInRegister:(int)regno atIdentifier:(NSString*)identifierName withScheme:(NSString*)scheme
{
    [self moveRegister:regno toRegister:2];
    int nameRegister = [self generateStringLiteral:identifierName intoRegister:1];
    int schemeRegister = [self generateStringLiteral:scheme intoRegister:0];
    [self moveRegister:nameRegister toRegister:1];
    [self moveRegister:schemeRegister toRegister:0];

    [codegen generateCallToExternalFunctionNamed:@"_st_scheme_at_put"];
    return 0;
}

-(int)generateLoadFromSymbolicAddress:(NSString*)symbol intoRegister:(int)regno
{
    [self generateLoadSymbolicAddress:symbol intoRegister:regno];
    [codegen loadRegister:regno fromContentsOfAdressInRegister:regno];
    return regno;
}

-(int)generateLoadClassReference:(NSString*)className intoRegister:(int)regno
{
    NSString *classRefLabel = [writer addClassReferenceForClass:className];
    return [self generateLoadFromSymbolicAddress:classRefLabel intoRegister:regno];
}

-(int)generateLoadClassReference:(NSString*)className
{
    return [self generateLoadClassReference:className intoRegister:0];
}

-(int)generateStaticBlockExpression:(MPWBlockExpression*)expr
{
    NSAssert1( expr.symbol != nil, @"block must have a symbol: %@",expr);
    [self generateLoadFromSymbolicAddress:expr.symbol intoRegister:0];
    return 0;
}

-(int)generateStackBlockExpression:(MPWBlockExpression*)block
{
    int stackOffset = block.stackOffset;
    [codegen generateAddDest:0 source:31 immediate:stackOffset];

    NSString *classRefLabel = [writer addClassReferenceForClass:@"_NSConcreteStackBlock" prefix:@"_"];
    [self generateLoadFromSymbolicAddress:classRefLabel intoRegister:8];

    [codegen generateMoveConstant:0x3e000000 to:9];     // flags
    [codegen generateSaveRegister:8 andRegister:9 relativeToRegister:0 offset:0 rewrite:NO pre:NO];

    [self generateLoadSymbolicAddress:block.blockFunctionSymbol intoRegister:10];  // class ptr
    [self generateLoadSymbolicAddress:block.blockDescriptorSymbol intoRegister:11];  // class ptr
    [codegen generateSaveRegister:10 andRegister:11 relativeToRegister:0 offset:16 rewrite:NO pre:NO];

    for ( STIdentifier *capturedIdentifier in block.capturedVariables) {
        NSString *idName = [capturedIdentifier path];
        int blockOffset = [[block capturedVariableOffets][idName] intValue];
        int sourceRegister = [self registerForLocalVar:idName];
        
        [codegen generateSaveRegister:sourceRegister andRegister:sourceRegister relativeToRegister:0 offset:blockOffset rewrite:NO pre:NO];
    }
    
    return 0;
}

-(BOOL)shouldGenerateStackBlockForBlockExpression:(MPWBlockExpression*)expr
{
    return self.forceStackBlocks || [expr needsToBeOnStack];
}

-(int)generateBlockExpression:(MPWBlockExpression*)expr
{
    NSLog(@"generate native code for block expression");
    if ( [self shouldGenerateStackBlockForBlockExpression:expr]) {
        return [self generateStackBlockExpression:expr];
    } else {
        return [self generateStaticBlockExpression:expr];
    }
}

-(int)generateStringLiteral:(NSString*)theString intoRegister:(int)regno
{
    stringLiteralNo++;
    NSString *literalSymbol=[NSString stringWithFormat:@"_CFSTR_L%d",stringLiteralNo];
    [writer writeNSStringLiteral:theString label:literalSymbol];
    [self generateLoadSymbolicAddress:literalSymbol intoRegister:regno];
    return regno;
}

-(int)generateStringLiteral:(NSString*)theString
{
    return [self generateStringLiteral:theString intoRegister:0];
}

-(void)generateCallToCreateObjectFromInteger
{
    [codegen generateCallToExternalFunctionNamed:@"_MPWCreateInteger"];
}

-(int)generateLiteralExpression:(MPWLiteralExpression*)expr
{
    id theLiteral=expr.theLiteral;
    if ( [theLiteral isKindOfClass:[NSNumber class]]) {
        int value = [theLiteral intValue];
        if ( value <= 0xffff) {
            [codegen generateMoveConstant:value to:0];
            [self generateCallToCreateObjectFromInteger];
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
    STExpression *rhs = [expr rhs];
    STIdentifier *lhs = [(STIdentifierExpression*)[expr lhs] identifier];;

    int registerForRHS = [self generateCodeFor:rhs];
    
    //  lhs is a local name
    
    NSString *lhsName = [lhs path];
    NSNumber *lhsRegisterNumber = self.variableToRegisterMap[lhsName];
    if ( lhsRegisterNumber ) {
        [self moveRegister:registerForRHS toRegister:lhsRegisterNumber.intValue];
        return lhsRegisterNumber.intValue;
    } else {
        NSString *lhsScheme = lhs.schemeName;
        [self generateStoreObjectInRegister:registerForRHS atIdentifier:lhsName withScheme:lhsScheme];
        return registerForRHS;
    }
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


-(int)generateCodeForExpression:(STExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't generate code for %@/%@ yet",expression.class,expression];
    return 0;
}

-(void)moveRegister:(int)source toRegister:(int)dest
{
    if (source != dest) {
//        NSLog(@"%d != %d, generate the move via %@",source,dest,codegen);
        [codegen generateMoveRegisterFrom:source to:dest];
    }
}

-(void)generateMessageSendToSelector:(NSString*)selector
{
    [self.codegen generateMessageSendToSelector:selector];
}

-(int)generateMessageSendOf:(NSString*)selectorString to:receiver with:args
{
    if (  NO &&  [selectorString isEqual:@"add:"] ) {
        id arg=args[0];
        if ( [arg isKindOfClass:[MPWLiteralExpression class]]) {
            MPWLiteralExpression *lit=(MPWLiteralExpression*)arg;
            [codegen generateAddDest:0 source:0 immediate:[[lit theLiteral] intValue]];
            return 0;
        } else {
            [NSException raise:@"unhandled" format:@"Only handling adds with constant right now"];
        }
    } else {
        int currentRegs = self.currentLocalRegStack;
        NSMutableArray *toEval = [NSMutableArray arrayWithObject:receiver];
        [toEval addObjectsFromArray:args];
        int numArgs = (int)toEval.count;
        int argRegisters[numArgs];
//        NSLog(@"%@ receiver + args: %@",NSStringFromSelector(expr.selector), toEval);
        for (int i=0;i<numArgs;i++) {
            if ( [toEval[i] isKindOfClass:[MPWMessageExpression class]] ||
                [toEval[i] isKindOfClass:[MPWLiteralExpression class]]
                ) {
                argRegisters[i]=[self allocateRegister];
//                NSLog(@"allocated register %d for arg %d",argRegisters[i],i);
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

        [self generateMessageSendToSelector:selectorString];

        self.currentLocalRegStack=currentRegs;
        return 0;
    }
    return 0;
}

-(int)generateMessageSend:(MPWMessageExpression*)expr
{
    NSString *selectorString = NSStringFromSelector(expr.selector);

    return [self generateMessageSendOf:selectorString to:expr.receiver with:expr.args];
}

-(int)generateCodeFor:(STExpression*)someExpression
{
    return [someExpression generateNativeCodeOn:self];
}

-(int)generateLiteralArrayExpression:(MPWLiteralArrayExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't generate code literal array %@/%@ yet",expression.class,expression];
    return 0;
}

-(int)generateLiteralDictionaryExpression:(MPWLiteralDictionaryExpression*)expression
{
    [NSException raise:@"unknown" format:@"Can't generate code for literal dict %@/%@ yet",expression.class,expression];
    return 0;
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

    self.currentLocalRegStack=self.localRegisterMin+totalArguments+numLocalVars;
    [self saveRegisters];
    

    [self moveRegister:0 toRegister:self.localRegisterMin];
    for (int i=0;i<totalArguments;i++) {
        [self moveRegister:i toRegister:self.localRegisterMin+i];
        self.variableToRegisterMap[args[i]]=@(self.localRegisterMin+i);
    }
    //--- save registers needed for local vars
    for (int i=0;i<numLocalVars;i++) {
        int currentRegister = self.localRegisterMin+i+totalArguments;
        [codegen clearRegister:self.localRegisterMin+i+totalArguments];
        self.variableToRegisterMap[localVars[i]]=@(currentRegister);
    }
}

-(void)saveLocalRegistersAndMoveArgs:(STScriptedMethod*)method
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

-(int)writeMethodBody:(STScriptedMethod*)method
{
    self.currentLocalRegStack=self.localRegisterMin;
    self.savedRegisterMax=self.localRegisterMin;

    [self saveLocalRegistersAndMoveArgs:method];
    int returnRegister =  [method.methodBody generateNativeCodeOn:self];
    [self restoreLocalRegisters];
    return returnRegister;
}

#define SIZE_OF_STACK_BLOCK 64

-(int)stackSpaceForMethod:(STScriptedMethod*)method
{
    return 0x120 + ((int)method.blocks.count * SIZE_OF_STACK_BLOCK);
}

-(NSString*)compileMethod:(STScriptedMethod*)method inClassNamed:className isClassMethod:(BOOL)isClassMethod
{
    NSArray *blocks = method.blocks;
    blockNo=0;
    self.currentBlockStackOffset=0;
    for ( MPWBlockExpression *block in blocks ) {
        NSString *blockSymbol = [self compileBlock:block inMethod:method];
        block.symbol = blockSymbol;
    }
    NSString *symbol = [NSString stringWithFormat:@"%@[%@ %@]",isClassMethod ? @"+":@"-", className,method.methodName];
    [self generateFunctionNamed:symbol stackSpace:[self stackSpaceForMethod:method] body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [self writeMethodBody:method];
    }];
    return symbol;
}

-(STJittableData*)generatedCode
{
    return self.codegen.generatedCode;
}

-(STJittableData*)compiledCodeForMethod:(STScriptedMethod*)method inClassNamed:aClass
{
    [self compileMethod:method inClassNamed:aClass isClassMethod:NO];
    return [self generatedCode];
}

-(STMethodSymbols*)compileMethodsInList:(NSArray<STScriptedMethod*>*)methods forClass:(STClassDefinition*)aClass info:(STMethodSymbols *)methodSymbols classMethods:(BOOL)classMethods
{
    for ( STScriptedMethod* method in methods) {
        [methodSymbols.methodNames addObject:method.methodName];
        [methodSymbols.methodTypes addObject:[[method header] typeString]];
        [methodSymbols.symbolNames addObject:[self compileMethod:method inClassNamed:aClass.name isClassMethod:classMethods]];
    }
    return methodSymbols;
}

-(void)compileMethodsForClass:(STClassDefinition*)aClass
{
    STMethodSymbols *instanceMethods=[[STMethodSymbols new] autorelease];
    NSArray *propertyPathMethods=[aClass propertyPathImplementationMethods];
    if ( propertyPathMethods.count) {
        [self compileMethodsInList:propertyPathMethods forClass:aClass info:instanceMethods classMethods:NO];
        PropertyPathDefs *getters=[aClass propertyPathDefsForVerb:MPWRESTVerbGET];
        NSAssert2(getters->count == propertyPathMethods.count, @"property path getter count %d not equal to method count %ld", getters->count,propertyPathMethods.count);
        NSString *propertyPathGetterListSymbol=[NSString stringWithFormat:@"_%@_PropertyPaths_get",aClass.name];
        [classwriter writePropertyDefStruct:getters symbolName:propertyPathGetterListSymbol functionSymbols:instanceMethods.symbolNames];
    }
    
    [self compileMethodsInList:aClass.methods forClass:aClass info:instanceMethods classMethods:NO];

    STMethodSymbols *classMethods=[[STMethodSymbols new] autorelease];
    [self compileMethodsInList:aClass.classMethods forClass:aClass info:classMethods classMethods:YES];
    
    [writer addTextSectionData:(NSData*)[codegen target]];
    [classwriter writeInstanceMethodList:instanceMethods ];
    [classwriter writeClassMethodList:classMethods];
}


-(void)defineMethodsForClassDefinition:(STClassDefinition*)classDefinition
{
    self.classes[classDefinition.name]=classDefinition;
   [self compileMethodsForClass:classDefinition];
}


-(void)compileClass:(STClassDefinition*)aClass
{
    classwriter.nameOfClass = aClass.name;
    classwriter.nameOfSuperClass = aClass.superclassNameToUse;
    [self compileMethodsForClass:aClass];
    [classwriter writeClass];
    [writer addClassReferenceForClass:aClass.name];
}

-(void)compileAndWriteClass:(STClassDefinition*)aClass
{
    [self compileClass:aClass];
    [writer writeFile];
}

-(void)generateFunctionNamed:(NSString*)name stackSpace:(int)stackSpace body:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    self.variableToRegisterMap = [NSMutableDictionary dictionary];
    [codegen generateFunctionNamed:name stackSpace:stackSpace body:block];
}

-(void)generateFunctionNamed:(NSString*)name body:(void(^)(STObjectCodeGeneratorARM* gen))block
{
    [self generateFunctionNamed:name stackSpace:codegen.defaultFunctionStackSpace body:block];
}


-(void)compileMainCallingClass:(NSString*)aClassName
{
    NSString *symbol = @"_main";
    [self generateFunctionNamed:symbol body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        [self generateStringLiteral:aClassName intoRegister:2];
//        [codegen loadRegister:2 fromContentsOfAdressInRegister:2];
        [codegen generateCallToExternalFunctionNamed:@"_runSTMain"];
//        [codegen generateMoveConstant:0 to:0];
    }];
}

-(void)compileBlockInvocatinFunction:(MPWBlockExpression*)aBlock inMethod:(STScriptedMethod*)method blockFunctionSymbol:(NSString*)symbol
{
    self.currentBlock = aBlock;
    [self generateFunctionNamed:symbol body:^(STObjectCodeGeneratorARM * _Nonnull gen) {
        
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
    self.currentBlock = nil;
    return ;
}



-(NSString*)compileBlock:(MPWBlockExpression*)aBlock inMethod:(STScriptedMethod*)method
{
    NSLog(@"compileBlock:inMethod:");
    aBlock.stackOffset = self.currentBlockStackOffset;
    int blockOffset = SIZE_OF_STACK_BLOCK;
    if ( aBlock.hasCaptures){
        NSMutableDictionary *capturedOffsets=[NSMutableDictionary dictionary];

        for ( STIdentifier *identifier in aBlock.capturedVariables) {
            capturedOffsets[identifier.path]=@(blockOffset);
            blockOffset += (8 * aBlock.numberOfCaptures);
        }
        aBlock.capturedVariableOffets=capturedOffsets;
    }
    self.currentBlockStackOffset += blockOffset;
    blockNo++;
    NSString *symbol = [NSString stringWithFormat:@"_block_invoke_%d",blockNo];
    [self compileBlockInvocatinFunction:aBlock inMethod:method blockFunctionSymbol:symbol];
    NSString *blockSymbol = [NSString stringWithFormat:@"_theBlock_l%d",blockNo];
    if ( [self shouldGenerateStackBlockForBlockExpression:aBlock]) {
        aBlock.blockFunctionSymbol = symbol;
        aBlock.blockDescriptorSymbol = [writer writeBlockDescritorWithCodeAtSymbol:symbol blockSymbol:blockSymbol signature:@"i"];
    } else {
        [writer writeBlockLiteralWithCodeAtSymbol:symbol blockSymbol:blockSymbol signature:@"i" global:YES];
        aBlock.symbol = blockSymbol;
    }
    return blockSymbol;
}

-(NSData*)compileClassToMachoO:(STClassDefinition*)aClass
{
    [self compileAndWriteClass:aClass];
    return (NSData*)[writer target];
}

-(NSData*)compileProcessToMachoO:(STClassDefinition*)theClass
{
    [self compileMainCallingClass:theClass.name];
    return [self compileClassToMachoO:theClass];
}

-(NSData*)compileBlockToMachoO:(MPWBlockExpression*)aBlock
{
    self.currentBlockStackOffset=0;
    [self compileBlock:aBlock inMethod:nil];
    [writer addTextSectionData:[codegen target]];
    [writer writeFile];
    return (NSData*)[writer target];
}

-(NSString*)commandToProcessObjects:(NSArray*)objects withCommand:(NSString*)baseCommand output:(NSString*)output inDir:(NSString*)dir withFrameworks:(NSArray*)frameworks
{
    NSMutableString *command=[NSMutableString string];
    if ( dir ) {
        [command appendFormat:@"cd %@;",dir];
    }
    [command appendString:baseCommand];
    [command appendFormat:@" -o  %@ ",output];
    for ( NSString *objectFilename in objects ) {
        [command appendFormat:@"%@.o ",objectFilename ];
    }
    
    [command appendFormat:@" -rpath /Library/Frameworks/ "];
    [command appendFormat:@" -F/Library/Frameworks "];
    [command appendFormat:@" -F/System/Library/Frameworks "];
    for ( NSString *frameworkName in frameworks) {
        [command appendFormat:@" -framework %@ ",frameworkName];
    }
    if (self.logging) {
        fprintf(stderr,"\n%s\n",[command UTF8String]);
    }
    return command;
}

-(int)shellOut:(NSString*)command
{
    int compileSuccess = system([command UTF8String]);
    return compileSuccess;
}



-(int)linkObjects:(NSArray*)objects toExecutable:(NSString*)executable inDir:(NSString*)dir withFrameworks:(NSArray*)frameworks
{
    return [self shellOut:[self commandToProcessObjects:objects withCommand:@"cc" output:executable inDir:dir withFrameworks:frameworks]];
}


-(int)linkObjects:(NSArray*)objects toSharedLibrary:(NSString*)lib inDir:(NSString*)dir withFrameworks:(NSArray*)frameworks
{
    return [self shellOut:[self commandToProcessObjects:objects withCommand:@"ld -dynamic -dylib_compatibility_version 1.0 -rpath @executable_path/ -dylib_current_version 1.0 -platform_version macos 13.0.0 14.1 -syslibroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk -dylib -current_version 1.0 -compatibility_version 1.0" output:lib inDir:dir withFrameworks:frameworks]];
}

-(NSArray*)defaultFrameworks
{
    return @[ @"ObjectiveSmalltalk", @"MPWFoundation", @"Foundation"];
}

-(int)linkObjects:(NSArray*)objects toExecutable:(NSString*)executable inDir:(NSString*)dir
{
    return [self linkObjects:objects toExecutable:executable inDir:dir withFrameworks:[self defaultFrameworks]];
}

-(int)linkObjects:(NSArray*)objects toExecutable:(NSString*)executable inDir:(NSString*)dir additionalFrameworks:(NSArray*)additionalFrameworks
{
    return [self linkObjects:objects toExecutable:executable inDir:dir withFrameworks:[additionalFrameworks arrayByAddingObjectsFromArray:[self defaultFrameworks]]];
}


@end


#import <MPWFoundation/DebugMacros.h>


@implementation STNativeCompiler(testing) 


+(void)testFindBlocksInMethod
{
    STNativeCompiler *compiler = [self compiler];
    STClassDefinition *theClass = [compiler compile:@"class Hi { -tester:cond { cond ifTrue: { 'trueBlock'. } ifFalse:{ 'falseBlock'. }. } }"];
    STScriptedMethod *firstMethod = [[theClass methods] firstObject];
    IDEXPECT( [firstMethod methodName],@"tester:", @"method name");
    NSArray *blocks = firstMethod.blocks;
    INTEXPECT(blocks.count, 2,@"number of blocks in method");
    MPWBlockExpression *trueBlock = blocks.firstObject;
    MPWBlockExpression *falseBlock = blocks.lastObject;
    MPWLiteralExpression *trueLiteral = [[trueBlock statementArray] firstObject];
    MPWLiteralExpression *falseLiteral = [[falseBlock statementArray] lastObject];
    EXPECTNOTNIL( trueBlock.method ,@"trueBlock should have method");
    EXPECTNOTNIL( falseBlock.method ,@"trueBlock should have method");
    IDEXPECT( trueLiteral.theLiteral, @"trueBlock",@"true block literal");
    IDEXPECT( falseLiteral.theLiteral, @"falseBlock",@"false block literal");
}


static int notOnStack = 0;

+(void)testPointerOnStackCheck
{
    void *ptr_to_something_on_stack = &_cmd;
    
    EXPECTTRUE([self isPointerOnStackAboveMe:ptr_to_something_on_stack], @"_cmd is on stack");
    EXPECTFALSE([self isPointerOnStackAboveMe:&notOnStack], @"static is not stack");
    IDEXPECT( [self isPointerOnStackAboveMeForST:&ptr_to_something_on_stack],@(true),@"on stack");
    IDEXPECT( [self isPointerOnStackAboveMeForST:&notOnStack],@(false),@"not on stack");
}

+(void)testObjectiveCBlocksWithCapturesAreOnStackAndWithoutCapturesNot
{
    id staticBlock=^{ return 2; };
    int a=2;
    id stackBlock=^{ return a+2; };
    EXPECTTRUE([self isPointerOnStackAboveMe:stackBlock], @"block with captured var is on stack");
    EXPECTFALSE([self isPointerOnStackAboveMe:staticBlock], @"block without captured var is not on stack");
}



+(void)testComputeStackSpaceForStackBlocks
{
    STNativeCompiler *compiler=[self stackBlockCompiler];
    STClassDefinition *classWithBlocks=[compiler compile:@"class StackBlockMethods {  -zero { 2. } -one {  { 2. }. } -two { { 2. }. { 3. }. } } "];
    NSArray <STScriptedMethod*>* methods=classWithBlocks.methods;
    INTEXPECT(methods.count,3,@"number of methods");
    INTEXPECT([compiler stackSpaceForMethod:methods[0]],0x120,@"0 blocks");
    INTEXPECT([compiler stackSpaceForMethod:methods[1]],0x160,@"1 block");
    INTEXPECT([compiler stackSpaceForMethod:methods[2]],0x1a0,@"2 blocks");
}

+(void)testComputeStackBlockOffsetsWithinFrame
{
    STNativeCompiler *compiler=[self stackBlockCompiler];
    STClassDefinition *classWithBlocks=[compiler compile:@"class StackBlockMethods {  -two { { 2. }. { 3. }. } } "];
    NSArray <STScriptedMethod*>* methods=classWithBlocks.methods;
    INTEXPECT(methods.count,1,@"number of methods");
    INTEXPECT([compiler stackSpaceForMethod:methods[0]],0x1a0,@"2 blocks");
    NSArray <MPWBlockExpression*>*  blocks=methods[0].blocks;
    [compiler compileBlock:blocks[0] inMethod:methods[0]];
    INTEXPECT(blocks[0].stackOffset,0x0,@"first block stack offset");
    [compiler compileBlock:blocks[1] inMethod:methods[0]];
    INTEXPECT(blocks[1].stackOffset,0x40,@"second block stack offset");
}





+(NSArray*)testSelectors
{
   return @[
       @"testFindBlocksInMethod",
       @"testPointerOnStackCheck",
       @"testObjectiveCBlocksWithCapturesAreOnStackAndWithoutCapturesNot",
       @"testComputeStackSpaceForStackBlocks",
       @"testComputeStackBlockOffsetsWithinFrame",
       
			];
}

@end

