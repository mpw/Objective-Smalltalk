//
//  MPWShellProcess.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 07/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWShellProcess : MPWObject {
    NSString *name;
    NSString *path;
    NSTask *task;
    NSMutableArray *arguments;
	BOOL doLines;
}

+(NSString*)findCommandOnPath:(NSString*)commandName;
+linesReturnedByCommand:(NSString*)command withArgs:args;
+resultOfRunningCommand:(NSString*)command withArgs:args;
+processWithName:(NSString*)aName;
-initWithName:(NSString*)aName arguments:(NSArray*)args;


@end
