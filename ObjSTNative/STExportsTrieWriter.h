//
//  MPWExportsTrieWriter.h
//  ObjSTNative
//
//  Builds Mach-O exports trie data structure for dyld
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STExportsTrieWriter : NSObject

// Add a symbol name (address can be set later with setAddress:forSymbol:)
-(void)addSymbol:(NSString*)symbol;

// Add a symbol to export with its address
-(void)addSymbol:(NSString*)symbol atAddress:(uint64_t)address;

// Set/update address for a previously added symbol
-(void)setAddress:(uint64_t)address forSymbol:(NSString*)symbol;

// Build and return the exports trie data
-(NSData*)trieData;

// Computed size of the trie (8-byte aligned) - can be called before addresses are set
-(int)trieSize;

// Computed size based on array of symbol names (static helper)
+(int)trieSizeForSymbols:(NSArray<NSString*>*)symbols;

@end

NS_ASSUME_NONNULL_END
