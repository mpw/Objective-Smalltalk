//
//  MPWMachOWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import <MPWFoundation/MPWFoundation.h>
#import "MPWARMObjectCodeGenerator.h"
#import "MPWByteStreamWithSymbols.h"

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSectionWriter;

@interface MPWMachOWriter : MPWByteStream <SymbolWriter>

@property (nonatomic, readonly) MPWMachOSectionWriter *textSectionWriter;

-(void)writeFile;
-(NSData*)data;




@end

NS_ASSUME_NONNULL_END
