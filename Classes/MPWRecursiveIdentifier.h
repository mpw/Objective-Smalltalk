//
//  MPWRecursiveIdentifier.h
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWIdentifier.h"


@interface MPWRecursiveIdentifier : MPWIdentifier {
	MPWIdentifier *nextIdentifier;
}

objectAccessor_h(MPWIdentifier*, nextIdentifier, setNextIdentifier )

@end
