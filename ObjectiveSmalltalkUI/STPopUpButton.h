//
//  STPopUpButton.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 22.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>
#import "ModelDidChangeNotification.h"

@protocol ModelDidChange;

NS_ASSUME_NONNULL_BEGIN

@interface STPopUpButton : NSPopUpButton

@property (nonatomic, strong)  MPWBinding *ref;
@property (nonatomic, strong)  MPWBinding *enabledRef;
@property (nonatomic, assign)  BOOL inProcessing;

@end

NS_ASSUME_NONNULL_END
