//
//  MPWVARBinding.h
//  MPWTalk
//
//  Created by Marcel Weiher on 17.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWBinding.h"


@interface MPWVARBinding : MPWBinding {
	id			baseObject;
    BOOL        isObserving;
}

-initWithBaseObject:newBase pathComponents:(NSArray*)newPathComponents;
-initWithBaseObject:newBase path:newPath;
+bindingWithBaseObject:newBase path:newPath;

@end
