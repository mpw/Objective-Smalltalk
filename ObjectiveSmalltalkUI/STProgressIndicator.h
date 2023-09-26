//
//  STProgressIndicator.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 25.09.23.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalkUI/ModelDidChangeNotification.h>

NS_ASSUME_NONNULL_BEGIN

@interface STProgressIndicator : NSProgressIndicator <ModelDidChange,ValidationDidChange>

@property (nonatomic, strong)  MPWBinding *ref,*enabledRef,*minRef,*maxRef;


@end

NS_ASSUME_NONNULL_END
