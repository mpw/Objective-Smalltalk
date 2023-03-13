//
//  STObjectTemplate.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 13.02.21.
//

#import <ObjectiveSmalltalk/STExpression.h>

@class MPWComplexLiteralExpression;

NS_ASSUME_NONNULL_BEGIN

@interface STObjectTemplate : STExpression

@property (nonatomic, strong) NSString *literalClassName;
@property (nonatomic, strong) MPWComplexLiteralExpression *literal;
@end

NS_ASSUME_NONNULL_END
