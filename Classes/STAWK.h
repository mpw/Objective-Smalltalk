//
//  STAWK.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 18.06.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STAWK : MPWFilter

@property (nonatomic,strong) NSString *separator;
@property (nonatomic,strong) id block;

@end

NS_ASSUME_NONNULL_END
