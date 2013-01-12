//
//  MPWSequentialScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 6/13/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MPWScheme.h"

@class MPWScheme;

@interface MPWSequentialScheme : MPWScheme {
	NSMutableArray *schemes;
}

+schemeWithSchemes:(NSArray*)newSchemes;
-(void)addScheme:(MPWScheme*)newScheme;
-(NSMutableArray*)schemes;

@end
