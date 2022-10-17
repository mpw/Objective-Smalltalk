//
//  MPWByteStreamWithSymbols.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SymbolWriter

-(int)declareGlobalSymbol:(NSString*)symbol atOffset:(int)offset;

@end

@protocol RelocationWriter

-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset;

@end

@interface MPWByteStreamWithSymbols : MPWByteStream

@property (nonatomic, nullable, strong) id <RelocationWriter> relocationWriter;
@property (nonatomic, nullable, strong) id <SymbolWriter> symbolWriter;

-(void)declareGlobalSymbol:(NSString*)symbol;
-(void)addRelocationEntryForSymbol:(NSString*)symbol;

@end

NS_ASSUME_NONNULL_END
