//
//  MPWBigInteger.h
//  ObjectiveArithmetic
//
//  Created by Marcel Weiher on 14.08.19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWBigInteger : NSObject

+(instancetype)numberWithString:(NSString*)s;
+(instancetype)numberWithLong:(long)l;
-(instancetype)add:(MPWBigInteger*)other;
-(instancetype)sub:(MPWBigInteger*)other;
-(instancetype)mul:(MPWBigInteger*)other;
-(instancetype)div:(MPWBigInteger*)other;

@end

NS_ASSUME_NONNULL_END
