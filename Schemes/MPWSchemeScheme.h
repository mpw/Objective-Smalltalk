//
//  MPWSchemeScheme.h
//  Arch-S
//
//  Created by Marcel Weiher on 6/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWVarScheme.h>


@interface MPWSchemeScheme : MPWAbstractStore {
	NSMutableDictionary *_schemes;
}

-(NSDictionary*)schemes;
-(void)setSchemeHandler:(id <MPWStorage>)aScheme   forSchemeName:(NSString*)schemeName;
+(instancetype)currentScheme;
+(void)setCurrentScheme:(MPWSchemeScheme*)newScheme;
+(instancetype)createGlobalSchemeScheme;

@end

FOUNDATION_EXPORT id st_scheme_at(NSString *scheme, NSString *identifier);
FOUNDATION_EXPORT void st_scheme_at_put(NSString *scheme, NSString *identifier, id value);
