//
//  MPWAppDelegate.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 31.03.19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStCompiler;

@interface MPWAppDelegate : NSObject

@property (nonatomic, strong) MPWStCompiler *compiler;

-(void)loadSmalltalkMethods;


@end

NS_ASSUME_NONNULL_END
