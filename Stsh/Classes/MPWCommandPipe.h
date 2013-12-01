//
//  MPWCommandPipe.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 23/12/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWCommandPipe : MPWObject {
	id	initialCommand;
	id	remainingCommandOrPipe;
}

-pipe:otherPipe;

@end
