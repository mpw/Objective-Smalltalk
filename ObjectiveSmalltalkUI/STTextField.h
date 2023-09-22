//
//  STTextField.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 27.02.21.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalkUI/ModelDidChangeNotification.h>

@protocol ModelDidChange;
NS_ASSUME_NONNULL_BEGIN

@interface STTextField : NSTextField<ModelDidChange,ValidationDidChange>

@property (nonatomic, strong)  MPWBinding *ref;
@property (nonatomic, strong)  MPWBinding *enabledRef;
@property (nonatomic, assign)  BOOL inProcessing;

@end

NS_ASSUME_NONNULL_END
