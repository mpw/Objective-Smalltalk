//
//  STObjectTemplate.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 13.02.21.
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWComplexLiteralExpression;

NS_ASSUME_NONNULL_BEGIN

@interface STObjectTemplate : MPWExpression

@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) MPWComplexLiteralExpression *literal;
@end

NS_ASSUME_NONNULL_END
