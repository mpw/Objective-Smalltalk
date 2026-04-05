//
//  MPWObjectPipeCommand.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 19/2/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWAbstractShellCommand.h"


@interface MPWObjectPipeCommand : MPWAbstractShellCommand
{
	id	commandClass;
}

-initWithCommandClass:newCommandClass name:newName;

@end
