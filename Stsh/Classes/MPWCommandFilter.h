//
//  MPWCommandFilter.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 06/03/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWCommandFilter : MPWFlattenStream {
	id	shellProcess;
	NSFileHandle*  processStdin;
	NSFileHandle*  processStdout;
	BOOL eofReached;
	BOOL configured;
	BOOL running;
	BOOL isTarget;
	BOOL doLines;
	id scanner;
}

-initWithTarget:aTarget command:aCommand;

@end

