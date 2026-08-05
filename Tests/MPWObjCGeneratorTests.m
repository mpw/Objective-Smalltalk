//
//  MPWObjCGeneratorTests.m
//  ObjectiveSmalltalk
//
//  Tests for MPWObjCGenerator, the Objective-C transpiler.
//  Extracted from STTests; grouped here as the generator gains
//  feature parity with the interpreter.
//

#import "MPWObjCGeneratorTests.h"
#import "MPWObjCGenerator.h"
#import "MPWLiteralExpression.h"
#import "STScriptedMethod.h"
#import "STClassDefinition.h"
#import "MPWSchemeScheme.h"
#import <objc/runtime.h>
#import <dlfcn.h>

@implementation MPWObjCGeneratorTests

+(void)testCreateObjectiveCForVariable
{
    id compiler = [[[self alloc] init] autorelease];
    id parsed = [@"a" compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"a", @"generating Objective-C didn't work");
}

+(void)testCreateObjectiveCForConstants
{
    id compiler = [[[self alloc] init] autorelease];
    id parsedNumber = [@"1" compileIn:compiler];
    id objcNumber = [parsedNumber evaluateIn:compiler] ;
    IDEXPECT( objcNumber, @(1), @"generating Objective-C for constant didn't work");
    id parsedString = [@"'hello'" compileIn:compiler];
    id objcString = [MPWObjCGenerator process:parsedString];
    IDEXPECT( objcString, @"@\"hello\"", @"generating Objective-C for constant string didn't work");
}

+(void)testCreateObjectiveCForUnaryMessageSend
{
    id compiler = [[[self alloc] init] autorelease];
    id parsed = [@"a class." compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"[a class]", @"generating Objective-C didn't work for unary message send");
}

+(void)testCreateObjectiveCForMessageSendWithArg
{
    id compiler = [self compiler];
    id parsed = [@"NSString stringWithString:'hello world!'." compileIn:compiler];
    id objcCode = [MPWObjCGenerator process:parsed];
    IDEXPECT( objcCode, @"[NSString stringWithString:@\"hello world!\"]", @"generating Objective-C didn't work");
}

+(void)testCreateObjectiveCForAssignment
{
    id parsed = [@"a := 'hello'." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"a = @\"hello\"", @"assignment generation");
}

+(void)testCreateObjectiveCForEscapedString
{
    MPWLiteralExpression *literal=[[[MPWLiteralExpression alloc] init] autorelease];
    literal.theLiteral=@"a\"b\nc";
    IDEXPECT([MPWObjCGenerator process:literal], @"@\"a\\\"b\\nc\"", @"Objective-C string escaping");
}

+(void)testCreateObjectiveCForLiteralArray
{
    id parsed = [@"#( 'one', 'two' )." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"@[@\"one\", @\"two\"]", @"array literal generation");
}

+(void)testCreateObjectiveCForBlock
{
    id parsed = [@"{ :item | item class. }." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"^id(id item) {\nreturn [item class];\n}", @"block generation");
}

+(void)testCreateObjectiveCForMethod
{
    STScriptedMethod *method=[[self compiler] parseMethodDefinition:@"-answerFor:value { value class. }"];
    IDEXPECT([MPWObjCGenerator process:method], @"- (id)answerFor:(id)value\n{\nreturn [value class];\n}\n", @"method generation");
}

+(void)testCreateObjectiveCForClass
{
    STClassDefinition *classDef=[[self compiler] compile:@"class __GeneratedObjC : NSObject { var value. -valueClass { value class. } }"];
    NSString *generated=[MPWObjCGenerator process:classDef];
    EXPECTTRUE([generated containsString:@"@interface __GeneratedObjC : NSObject"], @"class interface");
    EXPECTTRUE([generated containsString:@"id value;"], @"class ivar");
    EXPECTTRUE([generated containsString:@"@implementation __GeneratedObjC"], @"class implementation");
    EXPECTTRUE([generated containsString:@"return [value class];"], @"class method body");
}

#pragma mark - end-to-end (compile, link, load, run generated Objective-C)

+(int)runObjectiveCGeneratorSmokeTask:(NSString*)launchPath arguments:(NSArray*)arguments output:(NSString**)output
{
    NSTask *task=[[[NSTask alloc] init] autorelease];
    NSPipe *pipe=[NSPipe pipe];
    task.launchPath=launchPath;
    task.arguments=arguments;
    task.standardOutput=pipe;
    task.standardError=pipe;
    [task launch];
    [task waitUntilExit];
    NSData *data=[[pipe fileHandleForReading] readDataToEndOfFile];
    if (output) {
        *output=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return task.terminationStatus;
}

+(Class)loadObjectiveCGeneratorSmokeFixture
{
    static Class smokeClass=nil;
    if (smokeClass) return smokeClass;

    STCompiler *compiler=[self compiler];
    NSArray *definitions=@[
        [compiler compile:@"class __ObjCGeneratorSmokeClass { var label. var counter:int. -messagePassing { 'hello' uppercaseString. } -literalResult { #{ #key: 'value' } objectForKey:'key'. } -arrayLiteralResult { #( 'first', 'second' ) lastObject. } -numberLiteralResult { 42. } -blockResult { { :value | value uppercaseString. } value:'block'. } -storeResult { smokestore:value. } -localsResult { a := 3. b := 4. a+b. } -conditionalResult:x { x < 3 ifTrue:{ 'small'. } ifFalse:{ 'big'. }. } -loopResult:n { total := 0. 1 to:n do:{ :i | total := total + i. }. total. } -whileResult { var a. a := 1. { a < 100. } whileTrue:{ a := a * 2. }. a. } -collectResult { (#( 1, 2, 3 ) collect:{ :i | i * 2. }) lastObject. } -primitiveSum: a to: b { var x:int := a. var y:int := b. x + y. } -labelFor: x { r := 'small'. (x isEqual:'big') ifTrue:{ r := 'BIG' }. r. } -countItems: coll { n := 0. coll do:{ :x | n := n + 1 }. n. } -greet: name { \"Hello, {name}!\". } -primitiveSumTo: n { var limit:int := n. var sum:int := 0. 1 to:limit do:{ :i | sum := sum + i. }. sum. } -bumpAndGet { this:counter := this:counter + 1. this:counter. } }"],
        [compiler compile:@"scheme __ObjCGeneratorSmokeStore : MPWDictStore { }"],
        [compiler compile:@"filter __ObjCGeneratorSmokeFilter |{ ^object uppercaseString. }"],
    ];
    NSMutableString *source=[NSMutableString stringWithString:[MPWObjCGenerator standardImports]];
    for (id definition in definitions) {
        [source appendString:[MPWObjCGenerator process:definition]];
        [source appendString:@"\n"];
    }

    NSString *stem=[NSString stringWithFormat:@"objst-objc-generator-smoke-%d",[[NSProcessInfo processInfo] processIdentifier]];
    NSString *sourcePath=[NSTemporaryDirectory() stringByAppendingPathComponent:[stem stringByAppendingPathExtension:@"m"]];
    NSString *dylibPath=[NSTemporaryDirectory() stringByAppendingPathComponent:[stem stringByAppendingPathExtension:@"dylib"]];
    NSError *writeError=nil;
    BOOL wrote=[source writeToFile:sourcePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    EXPECTTRUE(wrote, ([NSString stringWithFormat:@"write generated Objective-C: %@",writeError]));
    if (!wrote) return Nil;

    NSString *frameworkPath=[[NSBundle bundleForClass:self] bundlePath];
    NSString *frameworkDirectory=[frameworkPath stringByDeletingLastPathComponent];
    NSString *compilerOutput=nil;
    int status=[self runObjectiveCGeneratorSmokeTask:@"/usr/bin/xcrun"
        arguments:@[ @"clang", @"-dynamiclib", @"-fblocks", @"-Wno-objc-method-access",
                     @"-F", frameworkDirectory, @"-framework", @"ObjectiveSmalltalk",
                     @"-framework", @"MPWFoundation", @"-framework", @"Foundation",
                     sourcePath, @"-o", dylibPath ]
        output:&compilerOutput];
    INTEXPECT(status,0,([NSString stringWithFormat:@"compile generated Objective-C:\n%@\nSource:\n%@",compilerOutput,source]));
    if (status) return Nil;

    NSString *signOutput=nil;
    status=[self runObjectiveCGeneratorSmokeTask:@"/usr/bin/codesign"
        arguments:@[ @"--force", @"--sign", @"-", dylibPath ] output:&signOutput];
    INTEXPECT(status,0,([NSString stringWithFormat:@"sign generated dylib: %@",signOutput]));
    if (status) return Nil;

    void *handle=dlopen(dylibPath.fileSystemRepresentation,RTLD_NOW|RTLD_GLOBAL);
    NSString *loadError=handle ? nil : [NSString stringWithUTF8String:dlerror()];
    EXPECTNOTNIL((id)handle,([NSString stringWithFormat:@"load generated dylib: %@",loadError]));
    smokeClass=NSClassFromString(@"__ObjCGeneratorSmokeClass");
    EXPECTNOTNIL(smokeClass,@"generated smoke class registered with Objective-C runtime");
    return smokeClass;
}

+(void)testObjectiveCGeneratorEndToEndMessagePassingAndLiterals
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"messagePassing")],@"HELLO",@"generated message passing");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"literalResult")],@"value",@"generated dictionary literal");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"arrayLiteralResult")],@"second",@"generated array literal");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"numberLiteralResult")],@(42),@"generated numeric literal");
}

+(void)testObjectiveCGeneratorEndToEndBlocks
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"blockResult")],@"BLOCK",@"generated block invocation");
}

+(void)testObjectiveCGeneratorEndToEndLocalsControlFlowAndLoops
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"localsResult")],@(7),@"generated locals + arithmetic");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"conditionalResult:") withObject:@(1)],@"small",@"generated ifTrue: branch");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"conditionalResult:") withObject:@(5)],@"big",@"generated ifFalse: branch");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"loopResult:") withObject:@(4)],@(10),@"generated to:do: accumulator (__block local)");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"whileResult")],@(128),@"generated whileTrue: accumulator");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"collectResult")],@(6),@"generated collect: higher-order message");
}

+(void)testObjectiveCGeneratorEndToEndTypedInstanceVariable
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"bumpAndGet")],@(1),@"typed int ivar increments through its accessors");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"bumpAndGet")],@(2),@"...and holds state");
}

+(void)testObjectiveCGeneratorEndToEndPrimitiveForLoop
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"primitiveSumTo:") withObject:@(5)],@(15),@"primitive to:do: accumulator runs as a C for loop");
}

+(void)testObjectiveCGeneratorEndToEndStringInterpolation
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"greet:") withObject:@"World"],@"Hello, World!",@"generated string interpolation");
}

+(void)testObjectiveCGeneratorEndToEndForeachLoop
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"countItems:") withObject:(@[@"a",@"b",@"c"])],@(3),@"generated C foreach counts elements");
}

+(void)testObjectiveCGeneratorEndToEndLoweredIfStatement
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"labelFor:") withObject:@"big"],@"BIG",@"lowered C if fired");
    IDEXPECT([instance performSelector:NSSelectorFromString(@"labelFor:") withObject:@"other"],@"small",@"lowered C if skipped");
}

+(void)testObjectiveCGeneratorEndToEndInstanceVariableAccessors
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    [instance performSelector:NSSelectorFromString(@"setLabel:") withObject:@"hello ivar"];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"label")],@"hello ivar",@"generated instance-variable accessor round-trips");
}

+(void)testObjectiveCGeneratorEndToEndPrimitiveComputation
{
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    id result=[instance performSelector:NSSelectorFromString(@"primitiveSum:to:") withObject:@(3) withObject:@(4)];
    IDEXPECT(result,@(7),@"generated unbox → C primitive add → box round-trips");
}

+(void)testObjectiveCGeneratorEndToEndIdentifiersAgainstStores
{
    MPWSchemeScheme *schemes=[MPWSchemeScheme currentScheme];
    MPWDictStore *store=[MPWDictStore store];
    [store at:@"value" put:@"from store"];
    [schemes setSchemeHandler:store forSchemeName:@"smokestore"];
    id instance=[[[self loadObjectiveCGeneratorSmokeFixture] new] autorelease];
    IDEXPECT([instance performSelector:NSSelectorFromString(@"storeResult")],@"from store",@"generated scheme identifier lookup");
}

+(void)testObjectiveCGeneratorEndToEndClassAndStoreDefinitions
{
    [self loadObjectiveCGeneratorSmokeFixture];
    Class storeClass=NSClassFromString(@"__ObjCGeneratorSmokeStore");
    EXPECTNOTNIL(storeClass,@"generated store definition");
    id store=[storeClass store];
    [store at:@"key" put:@"stored"];
    IDEXPECT([store at:@"key"],@"stored",@"generated store subclass behavior");
}

+(void)testObjectiveCGeneratorEndToEndFilterDefinition
{
    [self loadObjectiveCGeneratorSmokeFixture];
    Class filterClass=NSClassFromString(@"__ObjCGeneratorSmokeFilter");
    EXPECTNOTNIL(filterClass,@"generated filter definition");
    NSMutableArray *target=[NSMutableArray array];
    id filter=[filterClass streamWithTarget:target];
    [filter writeObject:@"mixed Case"];
    IDEXPECT(target.firstObject,@"MIXED CASE",@"generated filter method and forwarding");
}

#pragma mark - local variable declarations

+(NSString*)generateMethod:(NSString*)methodSource
{
    return [MPWObjCGenerator process:[[self compiler] parseMethodDefinition:methodSource]];
}

+(void)testBareAssignmentsDeclaredAsLocals
{
    NSString *generated=[self generateMethod:@"-compute { a := 3. b := 4. a+b. }"];
    EXPECTTRUE([generated containsString:@"id a;"], @"local a declared");
    EXPECTTRUE([generated containsString:@"id b;"], @"local b declared");
    EXPECTTRUE([generated containsString:@"return [a add:b];"], @"uses the locals");
}

+(void)testMethodArgumentsAreNotRedeclaredAsLocals
{
    NSString *generated=[self generateMethod:@"-double:n { n add:n. }"];
    EXPECTFALSE([generated containsString:@"id n;"], @"argument n must not be redeclared");
}

+(void)testLocalAssignedInsideBlockUsesBlockStorage
{
    NSString *generated=[self generateMethod:@"-sum:n { total := 0. 1 to:n do:{ :i | total := total + i. }. total. }"];
    EXPECTTRUE([generated containsString:@"__block id total;"], @"local mutated in a block needs __block");
    EXPECTFALSE([generated containsString:@"id n;"], @"argument n must not be redeclared");
}

+(NSString*)generateClass:(NSString*)source
{
    return [MPWObjCGenerator process:[[self compiler] compile:source]];
}

+(void)testObjectIvarUsesAsteriskTypeAndObjectAccessor
{
    NSString *generated=[self generateClass:@"class __IvarObject : NSObject { var name:NSString. }"];
    EXPECTTRUE([generated containsString:@"NSString* name;"], @"object ivar type keeps its asterisk");
    EXPECTTRUE([generated containsString:@"objectAccessor( NSString*, name, setName )"], @"object ivar accessor");
}

+(void)testIdIvarUsesIdAccessor
{
    NSString *generated=[self generateClass:@"class __IvarId : NSObject { var value. }"];
    EXPECTTRUE([generated containsString:@"id value;"], @"id ivar");
    EXPECTTRUE([generated containsString:@"idAccessor( value, setValue )"], @"id ivar accessor");
}

+(void)testPrimitiveIvarUsesCTypeAndScalarAccessor
{
    NSString *generated=[self generateClass:@"class __IvarInt : NSObject { var count:int. }"];
    EXPECTTRUE([generated containsString:@"long count;"], @"primitive ivar uses its C type");
    EXPECTTRUE([generated containsString:@"scalarAccessor( long, count, setCount )"], @"primitive ivar accessor");
}

+(void)testTypedInstanceVariableIsRespectedThroughThisScheme
{
    NSString *generated=[self generateClass:@"class __TypedIvarPerson : NSObject { var age:int. -<void>advance { this:age := this:age + 1. } }"];
    EXPECTTRUE([generated containsString:@"[self setAge:([self age] + 1)]"], @"an int ivar's arithmetic stays primitive C through its accessors");
    EXPECTFALSE([generated containsString:@"add:"], @"not the boxed object-arithmetic form");
}

+(void)testSemanticTypeWithoutObjcClassPuntsToId
{
    NSString *generated=[self generateClass:@"class __IvarMDA : NSObject { var t:Text. }"];
    EXPECTTRUE([generated containsString:@"id t;"], @"a semantic/MDA object type with no ObjC class maps to id");
    EXPECTFALSE([generated containsString:@"Text"], @"the MDA type name is not emitted");
}

+(void)testToDoLowersToCForLoopWithPrimitiveVariable
{
    NSString *generated=[self generateMethod:@"-loop:n { total := 0. 1 to:n do:{ :i | total := total + i. }. total. }"];
    EXPECTTRUE([generated containsString:@"for ( long i = 1; i <= [n longValue]; i++ ) {"], @"to:do: becomes a C for loop with a primitive counter");
    EXPECTTRUE([generated containsString:@"total = [total add:@(i)];"], @"the primitive counter is boxed where the body needs an object");
}

+(void)testToDoWithPrimitiveAccumulatorStaysPrimitive
{
    NSString *generated=[self generateMethod:@"-sumTo: n:int { var sum:int := 0. 1 to:n do:{ :i | sum := sum + i. }. sum. }"];
    EXPECTTRUE([generated containsString:@"for ( long i = 1; i <= n; i++ ) {"], @"a primitive bound is raw");
    EXPECTTRUE([generated containsString:@"sum = (sum + i);"], @"primitive accumulation stays C, no boxing");
}

+(void)testWhileTrueLowersToCWhileLoop
{
    NSString *generated=[self generateMethod:@"-whi { var a. a := 1. { a < 100 } whileTrue:{ a := a * 2 }. a. }"];
    EXPECTTRUE([generated containsString:@"while ( [a isLessThan:@(100)] ) {"], @"whileTrue: becomes a C while loop");
}

+(void)testDoLowersToCForeachLoop
{
    NSString *generated=[self generateMethod:@"-each: coll { r := 0. coll do:{ :x | r := r + 1 }. r. }"];
    EXPECTTRUE([generated containsString:@"for ( id x in coll ) {"], @"do: becomes a C fast-enumeration loop");
}

+(void)testInterpolatedStringGeneratesStringWithFormat
{
    id parsed=[@"\"hello {name}!\"." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"[NSString stringWithFormat:@\"hello %@!\", name]", @"one placeholder");
}

+(void)testInterpolatedStringWithMultiplePlaceholders
{
    id parsed=[@"\"{greeting} {name}\"." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"[NSString stringWithFormat:@\"%@ %@\", greeting, name]", @"two placeholders");
}

+(void)testDoubleQuotedStringWithoutPlaceholdersIsPlainString
{
    id parsed=[@"\"no placeholder\"." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"@\"no placeholder\"", @"no interpolation → plain string");
}

+(void)testThisSchemeReadGeneratesGetter
{
    id parsed=[@"a := this:hi." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"a = [self hi]", @"this: read generates a property getter");
}

+(void)testThisSchemeWriteGeneratesSetter
{
    id parsed=[@"this:hi := 2." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"[self setHi:@(2)]", @"this: write generates a property setter");
}

+(void)testStdoutGeneratesByteStreamStdout
{
    id parsed=[@"stdout." compileIn:[self compiler]];
    IDEXPECT([MPWObjCGenerator process:parsed], @"[MPWByteStream Stdout]", @"stdout is a special identifier");
}

+(void)testGeneratesPrimitiveArithmeticAsCOperators
{
    NSString *generated=[self generateMethod:@"-primitiveSum: a to: b { var x:int := a. var y:int := b. x + y. }"];
    EXPECTTRUE([generated containsString:@"long x;"], @"declared primitive local gets its C type");
    EXPECTTRUE([generated containsString:@"x = [a longValue];"], @"object argument unboxed into the primitive local");
    EXPECTTRUE([generated containsString:@"(x + y)"], @"primitive addition lowered to a C operator");
    EXPECTTRUE([generated containsString:@"return @((x + y));"], @"primitive result boxed at the object return boundary");
}

+(void)testDiscardedPrimitiveConditionalBecomesCIf
{
    NSString *generated=[self generateMethod:@"-check: age:int { r := 0. age > 10 ifTrue:{ r := 2 }. r. }"];
    EXPECTTRUE([generated containsString:@"if ( (age > 10) ) {"], @"lowered to a C if with a primitive condition");
    EXPECTFALSE([generated containsString:@"ifTrue:"], @"the ifTrue: message is gone");
}

+(void)testDiscardedConditionalWithElseBecomesCIfElse
{
    NSString *generated=[self generateMethod:@"-classify: x { r := 0. x < 3 ifTrue:{ r := 1 } ifFalse:{ r := 2 }. r. }"];
    EXPECTTRUE([generated containsString:@"if ( [x isLessThan:@(3)] ) {"], @"lowered to a C if");
    EXPECTTRUE([generated containsString:@"} else {"], @"with an else clause");
}

+(void)testValuePositionConditionalStaysAnExpression
{
    NSString *generated=[self generateMethod:@"-valuePos: x { x < 3 ifTrue:{ 'small'. } ifFalse:{ 'big'. }. }"];
    EXPECTTRUE([generated containsString:@"ifTrue:^id()"], @"a returned conditional keeps its expression form so its value survives");
}

+(void)testGeneratesPrimitiveComparisonAsCOperator
{
    NSString *generated=[self generateMethod:@"-less: a than: b { var x:int := a. var y:int := b. x < y. }"];
    EXPECTTRUE([generated containsString:@"(x < y)"], @"primitive comparison lowered to a C operator");
}

+(void)testExplicitVarDefinitionIsHoistedOnce
{
    NSString *generated=[self generateMethod:@"-count { var a. a := 1. { a < 4. } whileTrue:{ a := a * 2. }. a. }"];
    // a is mutated inside the whileTrue: block, so it must be a single __block declaration.
    EXPECTTRUE([generated containsString:@"__block id a;"], @"var mutated in block needs __block");
    INTEXPECT([[generated componentsSeparatedByString:@"id a"] count]-1, 1, @"declared exactly once");
}

+(NSArray*)testSelectors
{
    return @[
        @"testObjectIvarUsesAsteriskTypeAndObjectAccessor",
        @"testIdIvarUsesIdAccessor",
        @"testPrimitiveIvarUsesCTypeAndScalarAccessor",
        @"testTypedInstanceVariableIsRespectedThroughThisScheme",
        @"testSemanticTypeWithoutObjcClassPuntsToId",
        @"testToDoLowersToCForLoopWithPrimitiveVariable",
        @"testToDoWithPrimitiveAccumulatorStaysPrimitive",
        @"testWhileTrueLowersToCWhileLoop",
        @"testDoLowersToCForeachLoop",
        @"testInterpolatedStringGeneratesStringWithFormat",
        @"testInterpolatedStringWithMultiplePlaceholders",
        @"testDoubleQuotedStringWithoutPlaceholdersIsPlainString",
        @"testThisSchemeReadGeneratesGetter",
        @"testThisSchemeWriteGeneratesSetter",
        @"testStdoutGeneratesByteStreamStdout",
        @"testGeneratesPrimitiveArithmeticAsCOperators",
        @"testDiscardedPrimitiveConditionalBecomesCIf",
        @"testDiscardedConditionalWithElseBecomesCIfElse",
        @"testValuePositionConditionalStaysAnExpression",
        @"testGeneratesPrimitiveComparisonAsCOperator",
        @"testBareAssignmentsDeclaredAsLocals",
        @"testMethodArgumentsAreNotRedeclaredAsLocals",
        @"testLocalAssignedInsideBlockUsesBlockStorage",
        @"testExplicitVarDefinitionIsHoistedOnce",
        @"testCreateObjectiveCForVariable",
        @"testCreateObjectiveCForConstants",
        @"testCreateObjectiveCForUnaryMessageSend",
        @"testCreateObjectiveCForMessageSendWithArg",
        @"testCreateObjectiveCForAssignment",
        @"testCreateObjectiveCForEscapedString",
        @"testCreateObjectiveCForLiteralArray",
        @"testCreateObjectiveCForBlock",
        @"testCreateObjectiveCForMethod",
        @"testCreateObjectiveCForClass",
        @"testObjectiveCGeneratorEndToEndMessagePassingAndLiterals",
        @"testObjectiveCGeneratorEndToEndBlocks",
        @"testObjectiveCGeneratorEndToEndLocalsControlFlowAndLoops",
        @"testObjectiveCGeneratorEndToEndTypedInstanceVariable",
        @"testObjectiveCGeneratorEndToEndPrimitiveForLoop",
        @"testObjectiveCGeneratorEndToEndStringInterpolation",
        @"testObjectiveCGeneratorEndToEndForeachLoop",
        @"testObjectiveCGeneratorEndToEndLoweredIfStatement",
        @"testObjectiveCGeneratorEndToEndInstanceVariableAccessors",
        @"testObjectiveCGeneratorEndToEndPrimitiveComputation",
        @"testObjectiveCGeneratorEndToEndIdentifiersAgainstStores",
        @"testObjectiveCGeneratorEndToEndClassAndStoreDefinitions",
        @"testObjectiveCGeneratorEndToEndFilterDefinition",
    ];
}

@end
