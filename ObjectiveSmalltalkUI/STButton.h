//
//  STButton.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 04.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>
#import "ModelDidChangeNotification.h"

NS_ASSUME_NONNULL_BEGIN

@interface STButton : NSButton <ModelDidChange>

@property (nonatomic, strong)  MPWBinding *enabledRef;

@end

NS_ASSUME_NONNULL_END
