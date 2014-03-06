//
//  MPWBoxerUnboxer.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 3/6/14.
//
//

#import <Foundation/Foundation.h>

@interface MPWBoxerUnboxer : NSObject

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes;

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes;

+nspointBoxer;
+nsrangeBoxer;
+nsrectBoxer;

@end
