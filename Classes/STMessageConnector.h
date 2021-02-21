//
//  STMessageConnector.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 20.02.21.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STMessageConnector : STConnector

@property (assign) SEL selector;

-(instancetype)initWithSelector:(SEL)newSelector;

@end

NS_ASSUME_NONNULL_END
