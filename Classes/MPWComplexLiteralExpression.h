//
//  MPWComplexLiteralExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

//NS_ASSUME_NONNULL_BEGIN

@class STEvaluator;


@interface MPWComplexLiteralExpression : MPWExpression

@property (nonatomic, strong) NSString *literalClassName;

-(Class)classForContext:(STEvaluator*)aContext;
-factoryForContext:(STEvaluator*)aContext;

@end

@interface NSObject(factory)

+(id)factory;
+(id)factoryForContext:(STEvaluator*)aContext;

@end

// NS_ASSUME_NONNULL_END
