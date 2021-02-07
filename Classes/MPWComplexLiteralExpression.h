//
//  MPWComplexLiteralExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 07.02.21.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

//NS_ASSUME_NONNULL_BEGIN

@interface MPWComplexLiteralExpression : MPWExpression

@property (readonly) Class literalClass;
@property (nonatomic, strong) NSString *literalClassName;

@end

// NS_ASSUME_NONNULL_END
