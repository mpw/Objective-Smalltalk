//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPath.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWPropertyPathComponent.h"

@implementation MPWPropertyPath

-(NSString*)name
{
    return [(NSArray*)[[self.pathComponents collect] pathName] componentsJoinedByString:@"/"];
}

-(void)dealloc
{
    [_pathComponents release];
    [super dealloc];
}


@end
