//
//  MPWFileWatcher.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/14.
//
//

#import "MPWFileWatcher.h"

@implementation MPWFileWatcher


+watcher
{
    return [[[self alloc] init] autorelease];
}

-(void)watchFD:(int)fd type:(int)type queue:(dispatch_queue_t)queue block:(dispatch_block_t)handler
{
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,fd,
                                                      type,
                                                      queue);
    dispatch_source_set_event_handler(source,handler);
    dispatch_resume(source);
    
}


-(void)watchFile:(NSString*)filename withDelegate:delegate
{
    int fd=open([filename UTF8String], O_RDONLY);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [self watchFD:fd type:DISPATCH_VNODE_DELETE queue:queue block:^{
        NSLog(@"%@ delete",filename);
        [self watchFile:filename withDelegate:delegate];
        [delegate didChange];
    } ];
    [self watchFD:fd type:DISPATCH_VNODE_WRITE queue:queue block:^{
        [delegate didChange];
        NSLog(@"%@ write",filename);
    } ];
//    [self watchFD:fd type:DISPATCH_VNODE_LINK queue:queue block:^{
//        NSLog(@"%@ link",filename);
//    } ];
    [self watchFD:fd type:DISPATCH_VNODE_RENAME queue:queue block:^{
        NSLog(@"%@ rename",filename);
        [delegate didChange];
        [self watchFile:filename withDelegate:delegate];
    } ];
    
//    [self watchFD:fd type:DISPATCH_VNODE_REVOKE queue:queue block:^{
//        NSLog(@"%@ revoke",filename);
//    } ];
    
}

@end
