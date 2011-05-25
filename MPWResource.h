//
//  MPWResource.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWResource : NSObject {
	id			source;
	NSData		*rawData;
	NSString	*mimetype;
	id			_value;
}



@end
