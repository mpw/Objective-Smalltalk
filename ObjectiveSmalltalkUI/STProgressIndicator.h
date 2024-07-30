//
//  STProgressIndicator.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundationUI/MPWFoundationUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface STProgressIndicator : NSProgressIndicator <ModelDidChange,ValidationDidChange>

@property (nonatomic, strong)  MPWReference *ref,*enabledRef,*minRef,*maxRef;


@end

NS_ASSUME_NONNULL_END
