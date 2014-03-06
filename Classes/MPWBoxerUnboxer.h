//
//  MPWBoxerUnboxer.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 3/6/14.
//
//

#import <Foundation/Foundation.h>


typedef id (^BoxBlock)(void *buffer, int maxBytes);
typedef void (^UnboxBlock)(id anObject, void *buffer, int maxBytes);


@interface MPWBoxerUnboxer : NSObject

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes;

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes;

+nspointBoxer;
+nsrangeBoxer;
+nsrectBoxer;

+boxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer;

@end
