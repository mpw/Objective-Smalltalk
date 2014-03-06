//
//  MPWBoxerUnboxer.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 3/6/14.
//
//

#import "MPWBoxerUnboxer.h"
#import  <MPWFoundation/MPWFoundation.h>

@interface MPWNSPointBoxer : MPWBoxerUnboxer  @end
@interface MPWNSRectBoxer : MPWBoxerUnboxer  @end

@implementation MPWBoxerUnboxer


+nspointBoxer
{
    return [[MPWNSPointBoxer new] autorelease];
}

+nsrectBoxer
{
    return [[MPWNSRectBoxer new] autorelease];
}

+nsrangeBoxer
{
    return nil;
}

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    @throw [NSException exceptionWithName:@"notimplemented" reason:@"unbox not implemented" userInfo:nil];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    @throw [NSException exceptionWithName:@"notimplemented" reason:@"unbox not implemented" userInfo:nil];
}



@end


@implementation MPWNSPointBoxer

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    *(NSPoint*)buffer = [anObject pointValue];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    id retval= [MPWPoint pointWithNSPoint:*(NSPoint*)buffer];
    return retval;
}

@end



@implementation MPWNSRectBoxer

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    *(NSRect*)buffer = [anObject rectValue];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    id retval= [MPWRect rectWithNSRect:*(NSRect*)buffer];
    return retval;
}

@end
