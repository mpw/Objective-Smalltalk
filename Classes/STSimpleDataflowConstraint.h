//
//  STSimpleDataflowConstraint.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 18.04.21.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STSimpleDataflowConstraint : NSObject <Streaming>

@property (nonatomic,strong)  MPWBinding *source,*target;

@end

NS_ASSUME_NONNULL_END
