//
//  MPWConnectToDefault.m
//  MPWTalk
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import "MPWConnectToDefault.h"

@implementation MPWConnectToDefault

idAccessor( rhs, setRhs )
idAccessor( lhs, setLhs )


-(void)dealloc
{
    [lhs release];
    [rhs release];
    [super dealloc];
}

@end
