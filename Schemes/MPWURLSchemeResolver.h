//
//  MPWURLSchemeResolver.h
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWScheme.h>

@class MPWURLBinding;

@interface MPWURLSchemeResolver : MPWScheme {

}

-(instancetype)initWithSchemePrefix:(NSString*)schemeName;

+(instancetype)httpScheme;
+(instancetype)httpsScheme;


-(NSString*)schemePrefix;

@end
