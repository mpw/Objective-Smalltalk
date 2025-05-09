//
//  STQueryExpression.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 19.11.24.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STQueryExpression : STExpression

@property (nonatomic,strong) STExpression *receiver;
@property (nonatomic,strong) STExpression *predicate;


@end

@protocol Querying

-(NSArray*)evaluateQuery:(STQueryExpression*)query inContext:aContext;

@end


@interface NSArray(querying) <Querying>

@end

NS_ASSUME_NONNULL_END
