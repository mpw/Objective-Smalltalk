//
//  MPWCopyOnWriteScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/9/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWFilterScheme.h"
#import <MPWFoundation/MPWFoundation.h>

@interface MPWCopyOnWriteScheme : MPWFilterScheme
{
    MPWScheme *readWrite;
    BOOL cacheReads;
}

-initWithBase:(MPWScheme*)newBase cache:(MPWScheme*)newCache;
+cacheWithBase:(MPWScheme*)newBase cache:(MPWScheme*)newCache;
+cache:cacheScheme;
+memoryCache;


boolAccessor_h(cacheReads, setCacheReads)
objectAccessor_h(MPWScheme, readWrite, setReadWrite)

@end
