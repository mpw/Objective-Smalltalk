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

@property (readonly) Class literalClass;
@property (nonatomic, strong) NSString *literalClassName;

-(Class)classForContext:(MPWEvaluator*)aContext;

@end

// NS_ASSUME_NONNULL_END
