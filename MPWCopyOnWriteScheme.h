//
//  MPWCopyOnWriteScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 12/9/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWTreeNodeScheme.h"

@interface MPWCopyOnWriteScheme : MPWGenericScheme
{
    MPWScheme *readOnly,*readWrite;
}

@end
