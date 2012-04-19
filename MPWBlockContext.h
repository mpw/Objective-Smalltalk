//
//  MPWBlockContext.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWBlockInvocable.h>


@interface MPWBlockContext : MPWBlockInvocable {
	id	context;
	id	block;
}

+blockContextWithBlock:aBlock context:aContext;
-value;
-value:anObject;

@end
