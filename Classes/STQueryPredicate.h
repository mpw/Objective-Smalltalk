//
//  STQueryPredicate.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 23.09.25.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STQueryPredicate : MPWBlockExpression

-(NSPredicate*)asNSPredicate;

@end

NS_ASSUME_NONNULL_END
