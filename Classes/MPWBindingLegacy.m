//
//  MPWBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//
#import "MPWBindingLegacy.h"

@implementation MPWBinding(legacy)


-(void)setIdentifier:newIdentifier
{
    [self setReference:newIdentifier];
}

-(void)setScheme:newScheme
{
    [self setStore:newScheme];
}

-scheme
{
    return self.store;
}

-identifier
{
    return [self reference];
}

-(void)setDefaultContext:newContext
{
}

-initWithValue:aValue
{
    NSAssert1( aValue == nil,@"-initWithValue expecting nil, got %@",aValue);
    return [self init];
}

@end

