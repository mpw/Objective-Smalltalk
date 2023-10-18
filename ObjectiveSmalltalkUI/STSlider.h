//
//  STSlider.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundationUI/MPWFoundationUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface STSlider : NSSlider <ModelDidChange,ValidationDidChange>

@property (nonatomic, strong)  MPWBinding *ref;
@property (nonatomic, strong)  MPWBinding *enabledRef;

@end

NS_ASSUME_NONNULL_END
