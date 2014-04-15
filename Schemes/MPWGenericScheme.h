//
//  MPWGenericScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 11/21/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWScheme.h"

@class MPWGenericBinding;

@interface MPWGenericScheme : MPWScheme


-contentForURI:uri;
-(MPWBinding*)bindingForName:uriString inContext:aContext;
-valueForBinding:(MPWGenericBinding*)aBinding;
-(void)setValue:newValue forBinding:aBinding;
-(BOOL)hasChildren:(MPWGenericBinding*)binding;
-childWithName:(NSString*)name of:(MPWGenericBinding*)binding;
-(NSArray*)childrenOf:(MPWGenericBinding*)binding;
-(NSArray*)pathArrayForPathString:(NSString*)uri;

-(NSArray *)completionsForPartialName:(NSString *)partialName;


@end
