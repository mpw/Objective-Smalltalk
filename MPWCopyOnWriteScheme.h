//
//  MPWCopyOnWriteScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/9/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWTreeNodeScheme.h"
#import <MPWFoundation/MPWFoundation.h>

@interface MPWCopyOnWriteScheme : MPWGenericScheme
{
    MPWScheme *readOnly,*readWrite;
    BOOL cacheReads;
}

-initWithBase:(MPWScheme*)newBase cache:(MPWScheme*)newCache;
+cacheWithBase:(MPWScheme*)newBase cache:(MPWScheme*)newCache;


boolAccessor_h(cacheReads, setCacheReads)
objectAccessor_h(MPWScheme, readOnly, setReadOnly)
objectAccessor_h(MPWScheme, readWrite, setReadWrite)

@end
