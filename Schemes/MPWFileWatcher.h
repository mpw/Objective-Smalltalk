//
//  MPWFileWatcher.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/14.
//
//

#import <Foundation/Foundation.h>

@interface MPWFileWatcher : NSObject

-(void)watchFile:(NSString*)filename;
+(instancetype)watcher;


@end
