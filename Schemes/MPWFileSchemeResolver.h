//
//  MPWFileSchemeResolver.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/7/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWFileBinding;

@interface MPWFileSchemeResolver : MPWDiskStore {

}


-(void)startWatching:(MPWFileBinding*)binding;

@end
