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

@property (nonatomic, strong)  MPWReference *ref;
@property (nonatomic, strong)  MPWReference *enabledRef;

@end

NS_ASSUME_NONNULL_END
