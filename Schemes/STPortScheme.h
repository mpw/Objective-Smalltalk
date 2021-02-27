//
//  STPortScheme.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 26.02.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPortScheme : MPWAbstractStore

@property (nonatomic,strong) id <MPWStorage> source;

@end

NS_ASSUME_NONNULL_END
