//
//  MPWStringTableWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWStringTableWriter : NSObject

-(int)stringTableOffsetOfString:(NSString*)theString;

@property (readonly) long length;
@property (readonly) NSData *data;


@end

NS_ASSUME_NONNULL_END
