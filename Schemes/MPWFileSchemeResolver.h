//
//  MPWFileSchemeResolver.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWScheme.h>

@class MPWFileBinding;

@interface MPWFileSchemeResolver : MPWScheme {

}


-(void)startWatching:(MPWFileBinding*)binding;

@end
