//
//  MPWObjectFileWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWStringTableWriter;

@interface MPWObjectFileWriter : MPWByteStream

-(int)stringTableOffsetOfString:(NSString*)theString;

@property (readonly) MPWStringTableWriter *stringTableWriter;

@end

NS_ASSUME_NONNULL_END
