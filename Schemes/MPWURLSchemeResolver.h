//
//  MPWURLSchemeResolver.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWScheme.h>

@class MPWURLBinding,MPWResource;

@interface MPWURLSchemeResolver : MPWURLBasedStore {

}

-(instancetype)initWithSchemePrefix:(NSString*)schemeName;

+(instancetype)httpScheme;
+(instancetype)httpsScheme;


-(NSString*)schemePrefix;
-(MPWResource*)resourceWithRequest:(NSURLRequest*)request;

@end
