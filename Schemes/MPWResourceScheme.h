//
//  MPWResourceScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 5/15/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWScheme.h>


@interface MPWResourceScheme : MPWScheme {
	MPWScheme *underlyingScheme;
}

@end
