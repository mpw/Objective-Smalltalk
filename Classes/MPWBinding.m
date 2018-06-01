//
//  MPWBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//
#import "MPWBinding.h"

@implementation MPWBinding(legacy)

-(void)bindValue:newValue
{
    [self setValue:newValue];
    //    [self setIsBound:YES];
    //    [self didChange];
}

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

-name
{
    return [self.reference path];
}

-initWithValue:aValue
{
    NSAssert1( aValue == nil,@"-initWithValue expecting nil, got %@",aValue);
    return [self init];
}

@end

