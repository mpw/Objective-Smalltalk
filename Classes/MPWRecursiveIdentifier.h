//
//  MPWRecursiveIdentifier.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWIdentifier.h"


@interface MPWRecursiveIdentifier : MPWIdentifier {
	MPWIdentifier *nextIdentifer;
}

objectAccessor_h( MPWIdentifier, nextIdentifer, setNextIdentifier )

@end
