//
//  MPWSchemeScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWVarScheme.h"


@interface MPWSchemeScheme : MPWVarScheme {
	NSMutableDictionary *_schemes;
}

-(NSDictionary*)schemes;
-(void)setSchemeHandler:(MPWScheme*)aSchem   forSchemeName:(NSString*)schemeName;

@end
