//
//  MPWRelScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 5/10/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWPathRelativeStore.h>

@class MPWBinding;

@interface MPWRelScheme : MPWPathRelativeStore {
}

-initWithRef:(MPWBinding*)aBinding;

@end
