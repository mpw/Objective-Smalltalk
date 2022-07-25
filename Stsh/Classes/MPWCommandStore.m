//
//  MPWCommandStore.m
//  StshFramework
//
//  Created by Marcel Weiher on 24.07.22.
//

#import "MPWCommandStore.h"
#import "MPWShellProcess.h"
#import "MPWCommandBinding.h"

@implementation MPWCommandStore

-(id)at:(id<MPWReferencing>)aReference
{
    return [[self bindingForReference:aReference inContext:nil] value];
}

-(MPWCommandBinding *)bindingForReference:(id)aReference inContext:(id)aContext
{
    return [MPWCommandBinding bindingWithReference:aReference inStore:self];
}

@end


@implementation MPWCommandStore(testing)



@end
