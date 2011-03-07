//
//  MPWLLVMCompiler.m
//  MPWTalk
//
//  Created by Marcel Weiher on 17/8/06.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "MPWLLVMCompiler.h"
#import <MPWCodeGen/LLVMObjectiveCMethod.h>
#import "MPWStCompiler.h"

@implementation MPWLLVMCompiler

idAccessor( llvmMethod, setLlvmMethod )
idAccessor( methodHeader, setMethodHeader )

-valueOfVariableNamed:aName
{
	if ( [aName isEqual:@"self"] ) {
		NSLog(@"return receiver of method");
		return [llvmMethod receiver];
	} else {
		int parameterIndex;
		id parameterNames = [methodHeader parameterNames];
		if ( parameterNames && (NSNotFound != (parameterIndex=[parameterNames indexOfObject:aName]))) {
			NSLog(@"found parameter %@ %d",aName,parameterIndex);
			return [llvmMethod argumentAtIndex:parameterIndex];
		}
		id value = [super valueOfVariableNamed:aName];
		NSLog(@"value for name '%@': %@",aName,value);
		return value;
	}
//	return [localVars objectForKey:aName];
}

-numArguments
{
	return [methodHeader numArguments];
}

-initWithMethodHeader:newMethodHeader
{
	self = [super init];
	[self setMethodHeader:newMethodHeader];
	[self setLlvmMethod:[[[LLVMObjectiveCMethod alloc] initWithNumArgs:[self numArguments]] autorelease]];
	return self;
}

-init
{
	return [self initWithMethodHeader:[MPWMethodHeader methodHeaderWithString:@"doIt"]];
}

-(void*)blockWithName:(const char*)name forObject:anObject result:(id*)resultPtr
{
	id result;
	void *basicBlock = [llvmMethod pushNewBasicBlockNamed:"trueBlock"];
	result = [anObject evaluateIn:self];
	[llvmMethod popBasicBlock];
	if ( resultPtr ) {
		*resultPtr=result;
	}
	return basicBlock;
}

-handleConditionalWithCondition:condition trueBlock:trueBlock falseBlock:falseBlock
{
	void *trueBasicBlock,*falseBasicBlock;
	id trueResult,falseResult;
	trueBasicBlock = [self blockWithName:"trueBlock" forObject:trueBlock result:&trueResult];
	falseBasicBlock = [self blockWithName:"falseBlock" forObject:falseBlock result:&falseResult];
	[llvmMethod createConditionBasedOn:condition trueBlock:trueBasicBlock falseBlock:falseBasicBlock];
	
	return [llvmMethod phiNodeBB1:trueBasicBlock val1:trueResult bb2:falseBasicBlock val2:falseResult];
}

-sendMessage:(SEL)selector to:receiver withArguments:args
{
	id messageSend;
	id arg=[args objectAtIndex:0];
	receiver=[receiver evaluateIn:self];
	args=[self evaluatedArgs:args];
	if ( selector == @selector(ifTrue:ifFalse:)) {
		messageSend = [self handleConditionalWithCondition:receiver trueBlock:[args objectAtIndex:0] falseBlock:[args objectAtIndex:1]];
	} else {
		messageSend = [llvmMethod createMessageSendWithReceiver:receiver selector:selector args:args];
	}
	return messageSend;
}

-evaluateMethodBodyExpression:expr
{
	id lastValue = [expr evaluateIn:self];
	[llvmMethod setReturnValue:lastValue];
	return llvmMethod;
}

-expressionCompiledToFunction:expr
{
	[self evaluateMethodBodyExpression:expr];
	return llvmMethod;
}



@end


@interface MPWLLVMCompilerTester : NSObject 
@end

@implementation MPWLLVMCompilerTester

+(IMP)impForExpression:(NSString*)testscript methodHeaderString:(NSString*)methodHeaderString
{
	id compiler = [[[MPWStCompiler alloc] init] autorelease];
	id compiledExpr = [compiler compile:testscript];
	id llvm = [[[MPWLLVMCompiler alloc] initWithMethodHeader:[MPWMethodHeader methodHeaderWithString:methodHeaderString]] autorelease];
	id machineCompiled;
	IMP helloReturnFun;
	
	
	machineCompiled = [llvm expressionCompiledToFunction:compiledExpr];
	helloReturnFun = (IMP)[machineCompiled methodPointer];
	
	return helloReturnFun;
}

+(IMP)impForExpression:(NSString*)testscript
{
	return [self impForExpression:testscript methodHeaderString:@"doIt"];
}

+(void)testConstantStringReturn
{
	IMP helloReturnFun = [self impForExpression:@"'Hello World!'"];
	id result = helloReturnFun( nil , NULL );
	IDEXPECT( result, @"Hello World!", @"compiled constant return function");
}

+(void)testDifferentConstantStringReturn
{
	IMP helloReturnFun = [self impForExpression:@"'Goodbye World!'"];
	id result = helloReturnFun( nil , NULL );
	IDEXPECT( result, @"Goodbye World!", @"compiled constant return function");
}


+(void)testSelfReturn
{
	IMP helloReturnFun = [self impForExpression:@"self"];
	id result = helloReturnFun( @"Myself!" , NULL );
	IDEXPECT( result, @"Myself!", @"compiled self-return method");
	result = helloReturnFun( @"Again!" , NULL );
	IDEXPECT( result, @"Again!", @"compiled self-return method");
}

+(void)testMessageSendWithSelfAndLiterals
{
	IMP helloReturnFun = [self impForExpression:@"('Hello ' stringByAppendingString:self) stringByAppendingString:'!'."];
	id result = helloReturnFun( @"World" , NULL );
	IDEXPECT( result, @"Hello World!", @"compiled greeting message");
	result = helloReturnFun( @"Marcel" , NULL );
	IDEXPECT( result, @"Hello Marcel!", @"compiled greeting message");
}

+(void)testMessageSendWithMethodArguments
{
	IMP helloReturnFun = [self impForExpression:@"self stringByAppendingString:suffix." methodHeaderString:@"concat:suffix"];
	id result = helloReturnFun( @"Hello " , NULL, @"World!" );
	IDEXPECT( result, @"Hello World!", @"compiled greeting message");
}


+(void)testMethodWithConditional
{
	IMP helloGoodbye = [self impForExpression:@"self = 'Marcel' ifTrue:[ self appendString:',hello'.] ifFalse:[self appendString:',goodbye'.]. self." methodHeaderString:@"testIfMarcel"];
	id resultHello,resultGoodbye;
	NSLog(@"did compile, will run, function address: %x",helloGoodbye);
	resultHello = helloGoodbye( [NSMutableString stringWithString:@"Marcel"] , NULL );
	NSLog(@"did run once result: %x",resultHello);
	resultGoodbye = helloGoodbye( [NSMutableString stringWithString:@"Egon"] , NULL );
	NSLog(@"did run second time, result: %x",resultGoodbye);
	IDEXPECT( resultHello, @"Marcel,hello", @"compiled greeting message");
	IDEXPECT( resultGoodbye, @"Egon,goodbye", @"compiled greeting message");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testConstantStringReturn",
		@"testDifferentConstantStringReturn",
		@"testSelfReturn",
		@"testMessageSendWithSelfAndLiterals",
		@"testMessageSendWithMethodArguments",
		@"testMethodWithConditional",
		nil];
}

@end
