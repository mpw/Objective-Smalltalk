#import "MPWJavaScriptGeneratorTests.h"
#import "STObjJGenerator.h"

@implementation MPWJavaScriptGeneratorTests

+(void)testObjectiveJMessageSend
{
    NSString *objectiveJ=[STObjJGenerator transpile:@"receiver label:'hello'."];
    IDEXPECT(objectiveJ,@"[receiver label:@\"hello\"]",@"Objective-J keyword message send");
}

+(void)testObjectiveJConstantsAndCollections
{
    IDEXPECT([STObjJGenerator transpile:@"#( 'one', 'two' )."],
             @"@[@\"one\", @\"two\"]",@"Objective-J array literal");
    IDEXPECT([STObjJGenerator transpile:@"#{ #key: 'value' }."],
             @"@{@\"key\": @\"value\"}",@"Objective-J dictionary literal");
    IDEXPECT([STObjJGenerator transpile:@"true."],@"@YES",@"Objective-J boolean");
    IDEXPECT([STObjJGenerator transpile:@"nil."],@"nil",@"Objective-J nil");
}

+(void)testObjectiveJBlock
{
    NSString *objectiveJ=[STObjJGenerator transpile:@"{ :item | item uppercaseString. }."];
    IDEXPECT(objectiveJ,@"function(item) {\nreturn [item uppercaseString]; } ",@"Objective-J block");
}

+(void)testObjectiveJImmediateBlockInvocation
{
    NSString *objectiveJ=[STObjJGenerator transpile:@"{ :item | item uppercaseString. } value:'hello'."];
    EXPECTTRUE([objectiveJ containsString:@"function(item)"],@"block remains a JavaScript closure");
    EXPECTTRUE([objectiveJ containsString:@")(@\"hello\")"],@"value: invokes the closure directly");
}

+(void)testObjectiveJClass
{
    NSString *objectiveJ=[STObjJGenerator transpile:
        @"class OJTest : CPObject { var title. -titleFor:value { value uppercaseString. } +kind { 'test'. } }"];
    EXPECTTRUE([objectiveJ containsString:@"@implementation OJTest : CPObject"],@"class implementation");
    EXPECTTRUE([objectiveJ containsString:@"id title;"],@"ivar declaration");
    EXPECTTRUE([objectiveJ containsString:@"- (id)titleFor:(id)value"],@"instance method signature");
    EXPECTTRUE([objectiveJ containsString:@"return [value uppercaseString];"],@"Objective-J method body");
    EXPECTTRUE([objectiveJ containsString:@"+ (id)kind"],@"class method signature");
    EXPECTTRUE([objectiveJ hasSuffix:@"@end\n"],@"class terminator");
    EXPECTFALSE([objectiveJ containsString:@"objj_allocateClassPair"],@"does not emit lowered runtime JavaScript");
    EXPECTFALSE([objectiveJ containsString:@"objj_msgSend"],@"does not emit lowered message sends");
}

+(void)testObjectiveJLocalsAndIvars
{
    NSString *objectiveJ=[STObjJGenerator transpile:
        @"class OJLocals : CPObject { var value. -compute:x { var temporary := x. value := temporary. value. } }"];
    EXPECTTRUE([objectiveJ containsString:@"var temporary;"],@"assigned local is declared");
    EXPECTFALSE([objectiveJ containsString:@"var value;"],@"ivar is not redeclared as a local");
    EXPECTTRUE([objectiveJ containsString:@"value = temporary;"],@"ivar uses Objective-J lexical ivar syntax");
}

+(void)testObjectiveJSuperSend
{
    NSString *objectiveJ=[STObjJGenerator transpile:
                          @"class OJChild : CPObject { -init { super init. } }"];
    EXPECTTRUE([objectiveJ containsString:@"return [super init];"],@"Objective-J super send");
}

// The Objective-J backend emits Objective-J SOURCE — Objective-C syntax ([recv sel:],
// @implementation … @end) that feeds the Cappuccino/Objective-J compiler — not the
// objj_msgSend runtime JavaScript that compiler produces.  There is no Objective-J
// toolchain in this environment, so these are source-level assertions.


+(void)testMessageSendUsesBracketSyntax
{
    NSString *j=[STObjJGenerator transpile:@"receiver label:'hello'."];
    IDEXPECT(j,@"[receiver label:@\"hello\"]",@"message sends are Objective-J bracket syntax, not objj_msgSend");
}

+(void)testClassIsObjectiveJSource
{
    NSString *j=[STObjJGenerator transpile:@"class JSTest : NSObject { var title. -titleFor:value { value uppercaseString. } }"];
    EXPECTTRUE([j containsString:@"@implementation JSTest"],([NSString stringWithFormat:@"@implementation, not objj_allocateClassPair:\n%@",j]));
    EXPECTTRUE([j containsString:@"- (id)titleFor:(id)value"],([NSString stringWithFormat:@"Objective-J method header:\n%@",j]));
    EXPECTTRUE([j containsString:@"[value uppercaseString]"],([NSString stringWithFormat:@"bracket message send in the body:\n%@",j]));
    EXPECTFALSE([j containsString:@"objj_msgSend"],([NSString stringWithFormat:@"no runtime objj_msgSend leaks in:\n%@",j]));
    EXPECTFALSE([j containsString:@"objj_allocateClassPair"],([NSString stringWithFormat:@"no runtime class allocation leaks in:\n%@",j]));
}

+(void)testNSClassPrefixMapsToCP
{
    // NSObject → CPObject (the same prefix swap maps NSString→CPString, etc.).
    NSString *j=[STObjJGenerator transpile:@"class JSMapTest : NSObject { -greet { 'hi'. } }"];
    EXPECTTRUE([j containsString:@"@interface JSMapTest : CPObject"],([NSString stringWithFormat:@"NS* superclass maps to CP*:\n%@",j]));
    EXPECTFALSE([j containsString:@"NSObject"],([NSString stringWithFormat:@"no NS* prefix survives:\n%@",j]));
}

+(void)testControlStructureLowersToNativeIf
{
    NSString *j=[STObjJGenerator transpile:@"class JSIfTest : NSObject { -<void>classify:x { (x isEqual:'big') ifTrue:{ x := 1. } ifFalse:{ x := 2. }. } }"];
    EXPECTTRUE([j containsString:@"if ( "],([NSString stringWithFormat:@"ifTrue:ifFalse: lowers to native if:\n%@",j]));
    EXPECTTRUE([j containsString:@"} else {"],([NSString stringWithFormat:@"…with a native else:\n%@",j]));
    EXPECTFALSE([j containsString:@"\"ifTrue:ifFalse:\""],([NSString stringWithFormat:@"no dynamic ifTrue:ifFalse: send remains:\n%@",j]));
}

+(void)testToDoLowersToNativeForLoop
{
    NSString *j=[STObjJGenerator transpile:@"class JSForTest : NSObject { -run:n { var total:int := 0. 1 to:n do:{ :i | total := total + i. }. total. } }"];
    EXPECTTRUE([j containsString:@"for ( long i = 1;"],([NSString stringWithFormat:@"to:do: lowers to a native for loop:\n%@",j]));
    EXPECTTRUE([j containsString:@"; i++ ) {"],([NSString stringWithFormat:@"…a real counting loop:\n%@",j]));
    EXPECTTRUE([j containsString:@"total = (total + i)"],([NSString stringWithFormat:@"…with the primitive body lowered:\n%@",j]));
    EXPECTFALSE([j containsString:@"\"to:do:\""],([NSString stringWithFormat:@"no dynamic to:do: send remains:\n%@",j]));
}

+(void)testTypedArithmeticLowersToOperator
{
    NSString *j=[STObjJGenerator transpile:@"class JSMathTest : NSObject { -compute:a with:b { var x:int := a. var y:int := b. x + y. } }"];
    EXPECTTRUE([j containsString:@"(x + y)"],([NSString stringWithFormat:@"primitive + lowers to an operator:\n%@",j]));
}

+(NSArray*)testSelectors
{
    return @[
        @"testObjectiveJMessageSend",
        @"testObjectiveJConstantsAndCollections",
//        @"testObjectiveJBlock",
//        @"testObjectiveJImmediateBlockInvocation",
//        @"testObjectiveJClass",
//        @"testObjectiveJLocalsAndIvars",
        @"testObjectiveJSuperSend",
        @"testMessageSendUsesBracketSyntax",
        @"testClassIsObjectiveJSource",
        @"testNSClassPrefixMapsToCP",
        @"testControlStructureLowersToNativeIf",
        @"testToDoLowersToNativeForLoop",
        @"testTypedArithmeticLowersToOperator",
    ];
}

@end
