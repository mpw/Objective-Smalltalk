//
//  MPWFileWatcher.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/14.
//
//

#import <Foundation/Foundation.h>

@protocol FileWatching
-(void)didChange;
@end

@interface MPWFileWatcher : NSObject

+(instancetype)watcher;
-(void)watchFile:(NSString*)filename withDelegate:delegate;


@end
