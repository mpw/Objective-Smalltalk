//
//  MPWScriptingBridgeScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 5/31/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWVarScheme.h>


@interface MPWScriptingBridgeScheme : MPWVarScheme {
	NSMutableDictionary *bridges;
}

@end
