//
//  MPWMachOWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.09.22.
//

#import <MPWFoundation/MPWFoundation.h>
#import "MPWARMObjectCodeGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPWMachOWriter : MPWByteStream <SymbolWriter>

@property (nonatomic, strong) NSData *textSection;

-(void)writeFile;
-(NSData*)data;




@end

NS_ASSUME_NONNULL_END
