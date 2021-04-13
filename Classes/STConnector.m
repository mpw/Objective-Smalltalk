//
//  STConnector.m
//  Arch-S
//
//  Created by Marcel Weiher on 09/02/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import "STConnector.h"


@implementation STConnector

-(BOOL)isCompatible { return NO; }
-(BOOL)connect { return NO; }

-(void)dealloc
{
    [_source release];
    [_target release];
    [super dealloc];
}


@end
