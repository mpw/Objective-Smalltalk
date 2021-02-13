//
//  MPWComplexLiteralExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

//NS_ASSUME_NONNULL_BEGIN

@class MPWEvaluator;

@interface MPWComplexLiteralExpression : MPWExpression

@property (nonatomic, strong) NSString *literalClassName;

-(Class)classForContext:(MPWEvaluator*)aContext;
-factoryForContext:(MPWEvaluator*)aContext;

@end

@interface NSObject(factory)

+(id)factory;
+(id)factoryForContext:(MPWEvaluator*)aContext;

@end

// NS_ASSUME_NONNULL_END
