//
//  MPWStScript.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/10/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWStScript.h"
#import <ObjectiveSmalltalk/MPWMethodHeader.h>
#import "STShell.h"
#import "MPWShellCompiler.h"

#ifdef GS_API_LATEST

@implementation NSString(enumeration)

-(void)enumerateLinesUsingBlock:(void (^)(NSString *line, BOOL *stop))block
{
    NSArray *lines=[self componentsSeparatedByString:@"\n"];
    if ( lines.count && [lines.lastObject length]==0 ) {
        lines=[lines subarrayWithRange:NSMakeRange(0,lines.count-1)];
    }
    for (NSString *line in lines) {
        BOOL stop=NO;
        block( line, &stop);
        if (stop) {
            break;
        }
    }
}


@end

#endif


@implementation MPWStScript

idAccessor( data, setData )
idAccessor( methodHeader , setMethodHeader )
idAccessor( script, setScript )
objectAccessor(NSString*, filename, setFilename )

+scriptWithContentsOfFile:(NSString*)filename
{
	MPWStScript *script = [[[self alloc] initWithData:[NSData dataWithContentsOfFile:filename]] autorelease];
  [script setFilename:filename];
  return script;
}

-initWithData:(NSData*)newData
{
	self=[super init];
	[self setData:newData];
	[self parse];
	return self;
}


-(void)parse
{
    
    
//	id scanner=[[[MPWScanner alloc] initWithData:[self data]] autorelease];
	__block BOOL inComments=YES;
	NSString *commentPrefix=@"#";
	NSString *literalArrayPrefix=@"#(";
	NSMutableArray *scriptLines=[NSMutableArray array];
    NSString *scriptString=[[[NSString alloc] initWithData:[self data] encoding:NSUTF8StringEncoding] autorelease];
    [scriptString  enumerateLinesUsingBlock:^(NSString *exprString, BOOL *stop) {
        
        if ( [exprString hasPrefix:commentPrefix] && ![exprString hasPrefix:literalArrayPrefix] ) {
 			if ( inComments && [exprString hasPrefix:@"#-"] ) {
				id methodHeaderString=[exprString substringFromIndex:2];
				[self setMethodHeader:[MPWMethodHeader methodHeaderWithString:methodHeaderString]];
			}
        }  else {
			[scriptLines addObject:exprString];
			inComments=NO;
		}
    }];
    
	[self setScript:scriptLines];
}

-(BOOL)hasDeclaredReturn
{
    MPWMethodHeader *header=[self methodHeader];
	return header!= nil && ![[[header returnType] name] isEqual:@"void"];
}

-bindingForString:(NSString*)arg withContext:executionContext
{
    NSString *strarg=arg;
//    NSLog(@"string arg: %@",strarg);
    if ( [strarg rangeOfString:@":"].length<= 0 ) {
        strarg=[@"file:" stringByAppendingString:strarg];
    }
//    NSLog(@"arg: %@",strarg);
//    strarg=[@"ref:" stringByAppendingString:strarg];
//    NSLog(@"arg: %@",strarg);
    MPWBinding *binding=[[executionContext evaluator] bindingForString:strarg];
//    NSLog(@"binding: %@",binding);
//    NSLog(@"binding path: %@",[binding path]);
//    NSLog(@"binding url: %@",[binding URL]);
//    NSLog(@"binding url scheme: %@",[[binding URL] scheme]);
//    id reference=[binding reference];
//    NSLog(@"reference: %@",reference);
//    NSLog(@"reference path: %@",[reference path]);
    return binding;
}

-(void)processArgsFromExecutionContext:executionContext
{
	id args=[[[[executionContext evaluator] valueOfVariableNamed:@"args"] mutableCopy] autorelease];
	
	int i;
	if ( [methodHeader numArguments] <= [args count] ) {
		for (i=0;i<[methodHeader numArguments];i++ ) {
			id arg=[args objectAtIndex:0];
			NSString* argName=[methodHeader argumentNameAtIndex:i];
			NSString* argTypeName=[methodHeader argumentTypeNameAtIndex:i];

			//--- 'args' always takes up the 'remaining' args
			//--- but can appear at any point int the argument
			//--- list.
			
			if ( ![argName isEqual:@"args"] ) {
				if ( [argTypeName isEqual:@"int"] ) {
					arg=[NSNumber numberWithInt:[arg intValue]];
				} else if ([argTypeName isEqual:@"ref"] ) {
                    arg=[self bindingForString:arg withContext:executionContext];
                }
				[[executionContext evaluator] bindValue:arg toVariableNamed:argName];
				[args removeObjectAtIndex:0];
			}
		}
        [[executionContext evaluator] bindValue:[[args copy] autorelease] toVariableNamed:@"args"];
        NSArray *refs=[[self collect] bindingForString:[args each] withContext:executionContext];
        [[executionContext evaluator] bindValue:refs toVariableNamed:@"refs"];
    } else {
        long missingCount=[methodHeader numArguments] - [args count];
        NSMutableString *missingMsg;
        missingMsg=[NSMutableString stringWithFormat:@"<script> %ld missing parameters (of %d): ", missingCount,[methodHeader numArguments]];
        for (int i=0;i<[methodHeader numArguments];i++) {
            NSString *paramName=[methodHeader argumentNameAtIndex:i];
            if ( i< [args count] ) {
                [missingMsg appendFormat:@"%@ = %@ ",paramName,[args objectAtIndex:i]];
            } else {
                [missingMsg appendFormat:@"%@ = <missing> ",paramName];
            }
        }
        fprintf(stderr,"%s\n",[missingMsg UTF8String]);
//        [NSException raise:@"missingargument" format:missingMsg];
        exit(1);
    }
}

-(void)executeInContext_lines:(STShell *)executionContext
{
	id  scriptSource=[[self script] objectEnumerator];
	int line=1;
	NSString *exprString=nil;
	[self processArgsFromExecutionContext:executionContext];
	NS_DURING
    NSMutableString *accumulatedExpression=[NSMutableString string];
    while ( nil != (exprString=[scriptSource nextObject]) ) {
		id pool=[NSAutoreleasePool new];
        id expr = nil;
        id shellExpr = nil;
        [accumulatedExpression appendString:exprString];
		@try  {
            if ( [exprString hasPrefix:@"!"]) {
                shellExpr = [exprString substringFromIndex:1];
                system([shellExpr UTF8String]);
                [accumulatedExpression setString:@""];
            } else {
                expr = [[executionContext evaluator] compile:accumulatedExpression];
                [accumulatedExpression setString:@""];
            }
        } @catch (NSException *parseException ){
//            NSLog(@"keep looking because of exception: %@",parseException);

            line++;
            continue;
        }
		id localResult = [[executionContext evaluator] executeShellExpression:expr];
//        NSLog(@"localResult: %@",localResult);
		if ( [self hasDeclaredReturn] ) {
			[executionContext setRetval:localResult];
		}
		line++;
		[pool release];
	}
	if ( [self hasDeclaredReturn] ) {
//        NSLog(@"declared return: %@",[executionContext retval]);
        [executionContext evaluateReturnValue:[executionContext retval]];
//		[executionContext setRetval:nil];
//    } else {
//        NSLog(@"no declared return");
    }
	NS_HANDLER
		[[MPWByteStream Stderr] println:[NSString stringWithFormat:@"Exception: %@ in line %d: '%@' ",
					localException,line,exprString]];
	NS_ENDHANDLER
}

-(void)executeInContext_whole:(STShell *)executionContext
{
    NSString *exprString=[[self script] componentsJoinedByString:@"\n"];
    [self processArgsFromExecutionContext:executionContext];
    @try {
        @autoreleasepool {
            id expr = [[executionContext evaluator] compile:exprString];
            id localResult = [[executionContext evaluator] executeShellExpression:expr];
            if ( [self hasDeclaredReturn] ) {
                [executionContext setRetval:localResult];
            }
            if ( [self hasDeclaredReturn] ) {
                [[[MPWByteStream Stdout] do] println:[[executionContext retval] each]];
                [executionContext setRetval:nil];
            }
        }

    }
    @catch (NSException *exception) {
		[[MPWByteStream Stderr] println:[NSString stringWithFormat:@"Exception: %@ in : '%@' ",
                                         exception,exprString]];
    }
}

-(void)executeInContext:(STShell *)executionContext
{
    [self executeInContext_lines:executionContext];
}

@end

@implementation MPWStScript(testing)

+(void)testMultipleLineBlockExpression
{
    STShell *shell=[[[STShell alloc] init] autorelease];
    MPWStScript *script=[[[self alloc] initWithData:[@"#!/usr/local/bin/stsh\n#-<int>answer\n42" asData]] autorelease];
    [script executeInContext:shell];
    IDEXPECT([shell retval], @(42), @"simple expression");
}


+(void)testDefineAndUseClass
{
    STShell *shell=[[[STShell alloc] init] autorelease];
    MPWStScript *script=[[[self alloc] initWithData:[@"#!/usr/local/bin/stsh\n#-<int>answer\nclass MyObject : NSObject { -theAnswer { 45. } }.\nMyObject new theAnswer." asData]] autorelease];
    [script executeInContext:shell];
    IDEXPECT([shell retval], @(45), @"simple expression");
}





+testSelectors
{
    return @[
//             @"testMultipleLineBlockExpression",
//             @"testDefineAndUseClass",
              ];
}

@end


