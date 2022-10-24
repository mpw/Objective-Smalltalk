//
//  MPWMachOClassReader.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOReader,MPWMachORelocationPointer;

@interface MPWMachOClassReader : NSObject

-(instancetype)initWithPointer:(MPWMachORelocationPointer*)basePointer;
+(instancetype)readerWithPointer:(MPWMachORelocationPointer*)basePointer;
-(instancetype)metaclassReader;

-(int)instanceSize;
-(int)flags;
-(NSString*)nameOfClass;

-(MPWMachORelocationPointer*)superclassPointer;
-(MPWMachORelocationPointer*)cachePointer;

-(int)numberOfMethods;
-(int)methodEntrySize;
-(MPWMachORelocationPointer*)methodNameAt:(int)methodIndex;
-(MPWMachORelocationPointer*)methodTypesAt:(int)methodIndex;
-(MPWMachORelocationPointer*)methodCodeAt:(int)methodIndex;

@end

NS_ASSUME_NONNULL_END
