//
//  MPWBoxerUnboxer+MPWBoxingAdditions_m.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/8/14.
//
//

#import "MPWBoxerUnboxer+MPWBoxingAdditions.h"
#import "MPWInterval.h"


@implementation MPWBoxerUnboxer (MPWBoxingAdditions)

+(NSMutableDictionary*)createConversionDict
{
    return [[@{
               @(@encode(NSPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(NSSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGRect)): [MPWBoxerUnboxer nsrectBoxer],
               @(@encode(NSRect)): [MPWBoxerUnboxer nsrectBoxer],
               @(@encode(NSRange)): [MPWBoxerUnboxer nsrangeBoxer],
               } mutableCopy] autorelease];
}

+nsrangeBoxer
{
    return [self boxer:^id(void *buffer, int maxBytes) {
        NSRange rangeVal=*(NSRange*)buffer;
        return [MPWInterval intervalFromInt:rangeVal.location toInt:rangeVal.location+rangeVal.length-1];
    } unboxer:^(id anObject, void *buffer, int maxBytes) {
        NSRange *res=(NSRange*)buffer;
        *res=[anObject rangeValue];
    }];
}



@end
