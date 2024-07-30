//
//  MPWRecursiveIdentifier.h
//  Arch-S
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "STIdentifier.h"


@interface MPWRecursiveIdentifier : STIdentifier {
	STIdentifier *nextIdentifier;
}

objectAccessor_h(STIdentifier*, nextIdentifier, setNextIdentifier )

@end
