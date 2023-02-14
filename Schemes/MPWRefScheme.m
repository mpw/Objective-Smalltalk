//
//  MPWRefScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWRefScheme.h"
#import "MPWSelfContainedBinding.h"
#import "STEvaluator.h"
#import "MPWRecursiveIdentifier.h"

@implementation MPWRefScheme


-bindingForReference:(MPWRecursiveIdentifier*)anIdentifier inContext:(STEvaluator*)aContext
{
    MPWIdentifier* nextIdentifier = [anIdentifier nextIdentifier];
//    NSAssert1( [nextIdentifier scheme], @"nextIdentifier", nil );
    MPWScheme *originalScheme=[aContext schemeForName:[nextIdentifier schemeName]];
    id originalBinding = [originalScheme bindingWithIdentifier:nextIdentifier withContext:aContext];
//    NSLog(@"eval ref, original binding: %@",originalBinding);
    id binding = [MPWSelfContainedBinding bindingWithValue:originalBinding];
//    NSLog(@"eval ref, ref binding: %@",binding);
    return binding;
}

-bindingWithIdentifier:anIdentifier withContext:aContext
{
    return [self bindingForReference:anIdentifier inContext:aContext];
}


@end
