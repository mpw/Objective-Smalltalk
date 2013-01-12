//
//  MPWGetAccessor.h
//  MPWTalk
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWMethod.h>


@interface MPWGetAccessor : MPWMethod {
	id ivarDef;
}

+accessorForInstanceVariable:ivarDef;

@end
