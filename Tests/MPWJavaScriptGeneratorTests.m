#import "MPWJavaScriptGeneratorTests.h"
#import "MPWJavaScriptGenerator.h"

@implementation MPWJavaScriptGeneratorTests

+(void)testObjectiveJMessageSend
{
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:@"receiver label:'hello'."];
    IDEXPECT(objectiveJ,@"[receiver label:@\"hello\"];\n",@"Objective-J keyword message send");
}

+(void)testObjectiveJConstantsAndCollections
{
    IDEXPECT([MPWJavaScriptGenerator transpile:@"#( 'one', 'two' )."],
             @"@[@\"one\", @\"two\"];\n",@"Objective-J array literal");
    IDEXPECT([MPWJavaScriptGenerator transpile:@"#{ #key: 'value' }."],
             @"@{@\"key\": @\"value\"};\n",@"Objective-J dictionary literal");
    IDEXPECT([MPWJavaScriptGenerator transpile:@"true."],@"YES;\n",@"Objective-J boolean");
    IDEXPECT([MPWJavaScriptGenerator transpile:@"nil."],@"nil;\n",@"Objective-J nil");
}

+(void)testObjectiveJBlock
{
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:@"{ :item | item uppercaseString. }."];
    IDEXPECT(objectiveJ,@"function(item) {\nreturn [item uppercaseString];\n};\n",@"Objective-J block");
}

+(void)testObjectiveJImmediateBlockInvocation
{
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:@"{ :item | item uppercaseString. } value:'hello'."];
    EXPECTTRUE([objectiveJ containsString:@"function(item)"],@"block remains a JavaScript closure");
    EXPECTTRUE([objectiveJ containsString:@")(@\"hello\")"],@"value: invokes the closure directly");
}

+(void)testObjectiveJClass
{
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:
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
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:
        @"class OJLocals : CPObject { var value. -compute:x { temporary := x. value := temporary. value. } }"];
    EXPECTTRUE([objectiveJ containsString:@"var temporary;"],@"assigned local is declared");
    EXPECTFALSE([objectiveJ containsString:@"var value;"],@"ivar is not redeclared as a local");
    EXPECTTRUE([objectiveJ containsString:@"value = temporary;"],@"ivar uses Objective-J lexical ivar syntax");
}

+(void)testObjectiveJSuperSend
{
    NSString *objectiveJ=[MPWJavaScriptGenerator transpile:
        @"class OJChild : CPObject { -init { super init. } }"];
    EXPECTTRUE([objectiveJ containsString:@"return [super init];"],@"Objective-J super send");
}

+(NSArray*)testSelectors
{
    return @[
        @"testObjectiveJMessageSend",
        @"testObjectiveJConstantsAndCollections",
        @"testObjectiveJBlock",
        @"testObjectiveJImmediateBlockInvocation",
        @"testObjectiveJClass",
        @"testObjectiveJLocalsAndIvars",
        @"testObjectiveJSuperSend",
    ];
}

@end
