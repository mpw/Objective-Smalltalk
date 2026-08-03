#import "MPWJavaScriptGeneratorTests.h"
#import "MPWJavaScriptGenerator.h"
#import <JavaScriptCore/JavaScriptCore.h>

@implementation MPWJavaScriptGeneratorTests

+(NSString*)cappuccinoRuntimeHarness
{
    return @
    "var __classes = {};\n"
    "function sel_getUid(selector) { return selector; }\n"
    "function objj_method(name, implementation, types) { this.method_name=name; this.method_imp=implementation; this.method_types=types; }\n"
    "function __send(receiver, selector, args, startClass) {\n"
    "  if (receiver == null) return receiver;\n"
    "  for (var cls=startClass; cls; cls=cls.super_class) {\n"
    "    var method=cls.methods[selector];\n"
    "    if (method) return method.method_imp.apply(null, [receiver, selector].concat(args));\n"
    "  }\n"
    "  throw new Error('selector not found: ' + selector);\n"
    "}\n"
    "function __dispatch(receiver, selector) { return __send(receiver, selector, Array.prototype.slice.call(arguments, 2), this); }\n"
    "function objj_allocateClassPair(superclass, name) {\n"
    "  var cls={name:name, super_class:superclass, methods:{}, ivars:[], objj_msgSend:__dispatch};\n"
    "  var superMeta=superclass && superclass.isa;\n"
    "  cls.isa={name:name + '_meta', super_class:superMeta, methods:{}, objj_msgSend:__dispatch};\n"
    "  return cls;\n"
    "}\n"
    "function objj_registerClassPair(cls) { __classes[cls.name]=cls; }\n"
    "function objj_getClass(name) { return __classes[name] || null; }\n"
    "function class_addMethods(cls, methods) { methods.forEach(function(method) { cls.methods[method.method_name]=method; }); }\n"
    "function class_addIvars(cls, ivars) { cls.ivars=cls.ivars.concat(ivars); }\n"
    "function objj_ivar(name, type) { this.name=name; this.type=type; }\n"
    "function objj_msgSendSuper(info, selector) { return __send(info.receiver, selector, Array.prototype.slice.call(arguments, 2), info.super_class); }\n"
    "var CPObject=objj_allocateClassPair(null, 'CPObject');\n"
    "class_addMethods(CPObject.isa, [new objj_method('new', function(self) { return {isa:self}; }, ['id'])]);\n"
    "objj_registerClassPair(CPObject);\n"
    "String.prototype.isa={methods:{uppercaseString:new objj_method('uppercaseString', function(self) { return String(self).toUpperCase(); }, ['id'])}, objj_msgSend:__dispatch, super_class:null};\n";
}

+(JSContext*)contextEvaluating:(NSString*)javascript
{
    JSContext *context=[[[JSContext alloc] init] autorelease];
    __block JSValue *exception=nil;
    context.exceptionHandler=^(JSContext *ctx, JSValue *value) { exception=[value retain]; };
    [context evaluateScript:[self cappuccinoRuntimeHarness]];
    [context evaluateScript:javascript];
    EXPECTNIL(exception, ([NSString stringWithFormat:@"JavaScript exception: %@\nGenerated code:\n%@",exception,javascript]));
    [exception autorelease];
    return context;
}

+(void)testJavaScriptMessageSendMatchesCappuccinoABI
{
    NSString *javascript=[MPWJavaScriptGenerator transpile:@"receiver label:'hello'."];
    EXPECTTRUE([javascript containsString:@"receiver == null ? receiver : receiver.isa.objj_msgSend(receiver, \"label:\", \"hello\")"],
               ([NSString stringWithFormat:@"Cappuccino message-send ABI: %@",javascript]));
}

+(void)testJavaScriptClassOutputMatchesCappuccinoABI
{
    NSString *javascript=[MPWJavaScriptGenerator transpile:@"class JSTest : CPObject { var title. -titleFor:value { value uppercaseString. } }"];
    EXPECTTRUE([javascript containsString:@"objj_allocateClassPair(objj_getClass(\"CPObject\"), \"JSTest\")"],@"class allocation ABI");
    EXPECTTRUE([javascript containsString:@"class_addIvars(the_class"],@"ivar registration ABI");
    EXPECTTRUE([javascript containsString:@"new objj_method(sel_getUid(\"titleFor:\")"],@"method registration ABI");
    EXPECTTRUE([javascript containsString:@"objj_registerClassPair(the_class)"],@"class registration ABI");
}

+(void)testGeneratedJavaScriptClassAndMessageExecuteInJavaScriptCore
{
    NSString *javascript=[MPWJavaScriptGenerator transpile:@"class JSRuntimeTest : CPObject { -greet:name { name uppercaseString. } }"];
    JSContext *context=[self contextEvaluating:javascript];
    JSValue *result=[context evaluateScript:@"(function(){ var cls=objj_getClass('JSRuntimeTest'); var instance=cls.isa.objj_msgSend(cls, 'new'); return instance.isa.objj_msgSend(instance, 'greet:', 'hello'); })()"];
    IDEXPECT(result.toString,@"HELLO",@"generated class and message execute in JavaScriptCore");
}

+(void)testGeneratedJavaScriptIvarAssignmentExecutesInJavaScriptCore
{
    NSString *javascript=[MPWJavaScriptGenerator transpile:@"class JSIvarTest : CPObject { var value. -setAndGet:newValue { value := newValue. value. } }"];
    JSContext *context=[self contextEvaluating:javascript];
    JSValue *result=[context evaluateScript:@"(function(){ var cls=objj_getClass('JSIvarTest'); var instance=cls.isa.objj_msgSend(cls, 'new'); return instance.isa.objj_msgSend(instance, 'setAndGet:', 42); })()"];
    INTEXPECT(result.toInt32,42,@"generated assignment and return execute in JavaScriptCore");
}

+(NSArray*)testSelectors
{
    return @[
        @"testJavaScriptMessageSendMatchesCappuccinoABI",
        @"testJavaScriptClassOutputMatchesCappuccinoABI",
        @"testGeneratedJavaScriptClassAndMessageExecuteInJavaScriptCore",
        @"testGeneratedJavaScriptIvarAssignmentExecutesInJavaScriptCore",
    ];
}

@end
