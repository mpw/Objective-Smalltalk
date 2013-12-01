//
//  MPWStsh.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 26/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWObject.h>


@interface MPWStsh : MPWObject {
    id  Stdout,Stdin,Stderr;
    BOOL   readingFile;
    BOOL   echo;
	id		_evaluator;
    char   cwd[65536];
	id		retval;
    NSString *prompt;
    char  cstrPrompt[200];
}
+(void)runWithArgs:args;
-(void)addExternalCommand:(NSString*)externalCommandName;


@end

