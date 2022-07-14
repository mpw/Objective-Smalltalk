//
//  MPWHost.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.07.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWHost : NSObject

@property (readonly) NSString *name;
@property (readonly) NSString *user;


-(id <MPWStorage>)store;
-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output;
-(NSData*)run:(NSString*)command;


@end

NS_ASSUME_NONNULL_END
