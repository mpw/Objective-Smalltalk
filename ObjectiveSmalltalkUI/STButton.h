//
//  STButton.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 04.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundationUI/MPWFoundationUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface STButton : NSButton <ModelDidChange,ValidationDidChange>

@property (nonatomic, strong)  MPWReference *enabledRef;

@end

NS_ASSUME_NONNULL_END
