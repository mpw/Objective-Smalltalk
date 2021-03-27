//
//  MPWFastSuperMessage.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 27.03.21.
//

#import "MPWFastMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWFastSuperMessage : MPWFastMessage

@property (nonatomic,assign) Class superclassOfTarget;

@end

NS_ASSUME_NONNULL_END
