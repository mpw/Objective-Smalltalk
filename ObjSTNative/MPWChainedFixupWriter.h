//
//  MPWChainedFixupWriter.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 03.02.26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWChainedFixup : NSObject
@property(nonatomic, assign) int segmentIndex;
@property(nonatomic, assign) uint64_t offset;
@property(nonatomic, assign) int ordinal;
@property(nonatomic, assign) int next;
@property(nonatomic, assign) BOOL isRebase;       // YES = rebase, NO = bind
@property(nonatomic, assign) uint64_t rebaseTarget; // target address for rebases
@end

@interface MPWChainedFixupWriter : NSObject

@property(nonatomic, assign) uint32_t pageSize; // Default 0x4000 (16KB)

// Add an import
// Returns the ordinal [0...N]
- (int)addImport:(NSString *)symbolName fromDylib:(int)dylibOrdinal;

// Add a fixup (bind) at a specific offset within a segment
- (void)addBindAtSegment:(int)segmentIndex
                  offset:(uint64_t)offset
                 ordinal:(int)ordinal;

// Add a rebase at a specific offset within a segment
- (void)addRebaseAtSegment:(int)segmentIndex
                    offset:(uint64_t)offset
                    target:(uint64_t)target;

- (void)setSegmentFileOffset:(uint64_t)offset forSegment:(int)segmentIndex;

// Generate the full data block for LC_DYLD_CHAINED_FIXUPS
- (NSData *)fixupDataWithSegmentCount:(int)segmentCount;

// Helper to get fixups for a segment
- (NSArray<MPWChainedFixup *> *)fixupsForSegment:(int)segmentIndex;

// Helper to get bind entry bits
- (uint64_t)bind64Bits:(int)ordinal next:(int)next;

// Helper to get rebase entry bits
- (uint64_t)rebase64Bits:(uint64_t)target next:(int)next;

@end

NS_ASSUME_NONNULL_END
