#import "MPWJavaScriptGeneratorTests.h"
#import "STObjJGenerator.h"

// The Objective-J backend emits Objective-J SOURCE — Objective-C syntax ([recv sel:],
// @implementation … @end) that feeds the Cappuccino/Objective-J compiler — not the
// objj_msgSend runtime JavaScript that compiler produces.  There is no Objective-J
// toolchain in this environment, so these are source-level assertions.

@implementation MPWJavaScriptGeneratorTests

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
        @"testMessageSendUsesBracketSyntax",
        @"testClassIsObjectiveJSource",
        @"testNSClassPrefixMapsToCP",
        @"testControlStructureLowersToNativeIf",
        @"testToDoLowersToNativeForLoop",
        @"testTypedArithmeticLowersToOperator",
    ];
}

@end
