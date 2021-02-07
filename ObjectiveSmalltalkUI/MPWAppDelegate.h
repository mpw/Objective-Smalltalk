//
//  MPWAppDelegate.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 31.03.19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STCompiler;

@interface MPWAppDelegate : NSObject

@property (nonatomic, strong) STCompiler *compiler;

-(void)loadSmalltalkMethods;


@end

NS_ASSUME_NONNULL_END
