//
//  MPWFastMessage.h
//  Arch-S
//
//  Created by Marcel Weiher on 9/9/06.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWFastMessage : MPWObject {
	SEL selector;
	int	count;
}

+messageWithSelector:(SEL)aSelector typestring:(char*)newTypestring;
-sendTo:receiver withArguments:(id*)args count:(int)argCount;

@end
