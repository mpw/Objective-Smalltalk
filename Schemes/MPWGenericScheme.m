//
//  MPWGenericScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/21/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWGenericScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWGenericScheme

-(NSArray*)pathArrayForPathString:(NSString*)uri
{
	NSArray *pathArray = [uri componentsSeparatedByString:@"/"];
    if ( [pathArray count] > 1 && [[pathArray lastObject] length] == 0 ) {
        pathArray=[pathArray subarrayWithRange:NSMakeRange(0, [pathArray count]-1)];
    }
    return pathArray;
}

-(MPWBinding*)bindingForName:uriString inContext:aContext
{
	return [[[MPWGenericBinding alloc] initWithName:uriString scheme:self] autorelease];
}


-(BOOL)hasChildren:(MPWGenericBinding*)binding
{
    return NO;
}

-(NSArray*)childrenOf:(MPWGenericBinding*)binding
{
    return @[];
}

-(void)delete:(MPWGenericBinding*)binding
{
}

@end
