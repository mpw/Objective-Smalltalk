//
//  STMessageConnector.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.02.21.
//

#import <ObjectiveSmalltalk/STConnector.h>

NS_ASSUME_NONNULL_BEGIN

@class STMessagePortDescriptor;

@interface STMessageConnector : STConnector

@property (assign) SEL selector;
@property (nonatomic,strong) id  protocol;

@end

NS_ASSUME_NONNULL_END
