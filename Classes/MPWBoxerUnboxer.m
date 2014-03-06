//
//  MPWBoxerUnboxer.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 3/6/14.
//
//

#import "MPWBoxerUnboxer.h"
#import  <MPWFoundation/MPWFoundation.h>
#import  <MPWFoundation/AccessorMacros.h>
#import "MPWInterval.h"

@interface MPWNSPointBoxer : MPWBoxerUnboxer  @end
@interface MPWNSRectBoxer : MPWBoxerUnboxer  @end
@interface MPWBlockBoxer : MPWBoxerUnboxer

-initWithBoxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer;

@property (strong,nonatomic) UnboxBlock unboxBlock;
@property (strong,nonatomic) BoxBlock boxBlock;


@end

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
    return [self boxer:^id(void *buffer, int maxBytes) {
        NSRange rangeVal=*(NSRange*)buffer;
        return [MPWInterval intervalFromInt:rangeVal.location toInt:rangeVal.location+rangeVal.length-1];
    } unboxer:^(id anObject, void *buffer, int maxBytes) {
        NSLog(@"unbox range: %@",anObject);
        NSRange *res=(NSRange*)buffer;
        *res = [(MPWInterval*)anObject asNSRange];
        NSLog(@"unbox result: %@",NSStringFromRange(*res));
    }];
}


+boxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer
{
    return [[[MPWBlockBoxer alloc] initWithBoxer:newBoxer unboxer:newUnboxer] autorelease];
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



@implementation MPWBlockBoxer

-initWithBoxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer
{
    self=[super init];
    self.boxBlock = newBoxer;
    self.unboxBlock = newUnboxer;
    return self;
}



-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    self.unboxBlock( anObject, buffer, maxBytes);
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    return self.boxBlock( buffer, maxBytes);
}

@end


