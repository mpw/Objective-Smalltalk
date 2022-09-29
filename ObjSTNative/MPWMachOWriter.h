//
//  MPWMachOWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOWriter : MPWByteStream

@property (nonatomic, strong) NSData *textSection;

-(void)addGlobalSymbol:(NSString*)symbol atOffset:(int)offset;
-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset;
-(void)writeFile;
-(NSData*)data;




@end

NS_ASSUME_NONNULL_END
