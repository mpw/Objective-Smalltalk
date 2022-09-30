//
//  MPWARMObjectCodeGenerator.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.09.22.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SymbolWriter

-(void)addGlobalSymbol:(NSString*)symbol atOffset:(int)offset;
-(void)addRelocationEntryForSymbol:(NSString*)symbol atOffset:(int)offset;

@end

@interface MPWARMObjectCodeGenerator : MPWByteStream

@property (nonatomic, strong)  NSDictionary *symbolOffsets;
@property (nonatomic, nullable, strong) id <SymbolWriter> symbolWriter;
@end



NS_ASSUME_NONNULL_END
