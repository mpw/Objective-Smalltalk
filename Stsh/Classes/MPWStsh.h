//
//  MPWStsh.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 26/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWObject.h>

@class MPWByteStream,MPWEvaluator,STCompiler;

@interface MPWStsh : MPWObject {
    MPWByteStream  *Stdout,*Stdin,*Stderr;
    BOOL   readingFile;
    BOOL   echo;
	MPWEvaluator*		_evaluator;
    char   cwd[65536];
	id		retval;
    NSString *prompt;
    char  cstrPrompt[200];
    int   completionLimit;
}
+(void)runWithArgs:(NSArray*)args;
+(void)runWithArgCount:(int)argc argStrings:(const char**)argv;
-initWithArgs:args;
-(STCompiler*)evaluator;
-retval;
-(void)setRetval:newRetval;
-(void)run;

@property (nonatomic,strong) NSArray *args;

@end


@interface NSObject(executeInShell)

-executeInShell:aShell;

@end
