//
//  MPWPropertyPathComponent.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPathComponent.h"

@implementation MPWPropertyPathComponent

-(NSString*)pathName
{
    NSMutableString *pathName=[NSMutableString string];
    if ( [self isWildcard]) {
        [pathName appendString:@"*"];
    }
    if ( [self parameter]) {
        [pathName appendString:@":"];
        [pathName appendString:self.parameter];
    } else  if ( self.name) {
        [pathName appendString:self.name];
    }
    return pathName;
}

-(void)dealloc
{
    [_name release];
    [_parameter release];
    [super dealloc];    
}

@end
