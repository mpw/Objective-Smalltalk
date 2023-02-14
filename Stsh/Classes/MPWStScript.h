//
//  MPWStScript.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/10/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class STShell;

@interface MPWStScript : MPWObject {
	id  filename;
	id	data;
	id	methodHeader;
	id  script;
}

+scriptWithContentsOfFile:(NSString*)filename;

-(void)executeInContext:(STShell *)executionContext;


@end
