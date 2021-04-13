//
//  MPWRefScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 25.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWRefScheme.h"
#import "MPWSelfContainedBinding.h"
#import "MPWEvaluator.h"
#import "MPWRecursiveIdentifier.h"

@implementation MPWRefScheme


-bindingForReference:(MPWRecursiveIdentifier*)anIdentifier inContext:(MPWEvaluator*)aContext
{
    MPWIdentifier* nextIdentifer = [anIdentifier nextIdentifer];
//    NSAssert1( [nextIdentifer scheme], @"nextIdentifer", nil );
    MPWScheme *originalScheme=[aContext schemeForName:[nextIdentifer schemeName]];
    id originalBinding = [originalScheme bindingWithIdentifier:nextIdentifer withContext:aContext];
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
