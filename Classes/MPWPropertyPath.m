//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPath.h"

@implementation MPWPropertyPath

-(NSString*)name
{
    return [self.pathComponents componentsJoinedByString:@"/"];
}

-(NSString*)identifierName
{
    return [self name];
}

-(void)dealloc
{
    [_pathComponents release];
    [super dealloc];
}


@end
