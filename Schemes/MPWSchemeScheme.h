//
//  MPWSchemeScheme.h
//  MPWTalk
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

@end
