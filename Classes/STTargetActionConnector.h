//
//  STTargetActionConnector.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 25.02.21.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@interface STTargetActionConnector : STConnector

@property (assign) SEL message;

-(instancetype)initWithSelector:(SEL)newSelector;

@end

NS_ASSUME_NONNULL_END
