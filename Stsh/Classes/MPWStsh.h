//
//  MPWStsh.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 26/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWObject.h>

@class MPWByteStream,MPWEvaluator;

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
-evaluator;
-retval;
-(void)setRetval:newRetval;



@end


@interface NSObject(executeInShell)

-executeInShell:aShell;

@end