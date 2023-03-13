//
//  STSubscriptExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 29.07.21.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STSubscriptExpression : STExpression

@property (nonatomic,strong) STExpression *receiver;
@property (nonatomic,strong) STExpression *subscript;

-evaluateAssignmentOf:value in:aContext;


@end

NS_ASSUME_NONNULL_END
