//
//  MPWStScript.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/10/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class STShell,STBundle;

@interface STScript : MPWObject {
	id  filename;
	id	data;
	id	methodHeader;
	id  script;
}

@property (nonatomic, assign) bool shouldEvaluateReturnValue;
@property (nonatomic, strong) STBundle* bundle;

+scriptWithContentsOfFile:(NSString*)filename;

-(void)executeInContext:(STShell *)executionContext;


@end
