//
//  MPWCopyOnWriteScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/9/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWCopyOnWriteScheme : MPWMappingStore
{
    MPWAbstractStore *readWrite;
    BOOL cacheReads;
}

-initWithBase:(MPWAbstractStore*)newBase cache:(MPWAbstractStore*)newCache;
+cacheWithBase:(MPWAbstractStore*)newBase cache:(MPWAbstractStore*)newCache;
+cache:cacheScheme;
+memoryCache;


boolAccessor_h(cacheReads, setCacheReads)
objectAccessor_h(MPWAbstractStore, readWrite, setReadWrite)

@end
