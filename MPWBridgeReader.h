//
//  MPWBridgeReader.h
//  MPWXmlKit
//
//  Created by Marcel Weiher on 6/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWObject.h>


@interface MPWFallbackBridgeReader : MPWObject {
	id	context;
}

-initWithContext:aContext;
+(void)parseBridgeDict:aDict forContext:aContext;

-parse:xmlData;


@end
