//
//  MPWChainedFixupWriter.m
//  ObjSTNative
//

#import "MPWChainedFixupWriter.h"
#import "mach-o/fixup-chains.h"

@interface MPWChainedImport : NSObject
@property(nonatomic, strong) NSString *symbolName;
@property(nonatomic, assign) int dylibOrdinal;
@end

@implementation MPWChainedImport
@end

@implementation MPWChainedFixup
@end

@interface MPWChainedFixupWriter ()
- (uint64_t)bind64Bits:(int)ordinal next:(int)next;
@end

@implementation MPWChainedFixupWriter {
  NSMutableArray *imports;
  NSMutableArray *fixups;
  uint64_t *segmentFileOffsets;
  int _segmentCount;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    self.pageSize = 0x4000;
    imports = [[NSMutableArray alloc] init];
    fixups = [[NSMutableArray alloc] init];
  }
  return self;
}

- (int)addImport:(NSString *)symbolName fromDylib:(int)dylibOrdinal {
  // Check if already present
  for (int i = 0; i < imports.count; i++) {
    MPWChainedImport *imp = imports[i];
    if ([imp.symbolName isEqualToString:symbolName] &&
        imp.dylibOrdinal == dylibOrdinal) {
      return i;
    }
  }
  MPWChainedImport *imp = [[MPWChainedImport alloc] init];
  imp.symbolName = symbolName;
  imp.dylibOrdinal = dylibOrdinal;
  [imports addObject:imp];
  return (int)imports.count - 1;
}

- (void)addBindAtSegment:(int)segmentIndex
                  offset:(uint64_t)offset
                 ordinal:(int)ordinal {
  MPWChainedFixup *f = [[MPWChainedFixup alloc] init];
  f.segmentIndex = segmentIndex;
  f.offset = offset;
  f.ordinal = ordinal;
  f.isRebase = NO;
  [fixups addObject:f];
//  NSLog(@"MPWChainedFixupWriter: addBindAtSegment:%d offset:0x%llx ordinal:%d",
//        segmentIndex, offset, ordinal);
}

- (void)addRebaseAtSegment:(int)segmentIndex
                    offset:(uint64_t)offset
                    target:(uint64_t)target {
  MPWChainedFixup *f = [[MPWChainedFixup alloc] init];
  f.segmentIndex = segmentIndex;
  f.offset = offset;
  f.isRebase = YES;
  f.rebaseTarget = target;
  [fixups addObject:f];
//  NSLog(@"MPWChainedFixupWriter: addRebaseAtSegment:%d offset:0x%llx target:0x%llx",
//        segmentIndex, offset, target);
}

- (void)setSegmentFileOffset:(uint64_t)offset forSegment:(int)segmentIndex {
  if (!segmentFileOffsets || segmentIndex >= _segmentCount) {
    // Need to grow the array - preserve existing values
    int newCount = segmentIndex + 1;
    uint64_t *newOffsets = calloc(newCount, sizeof(uint64_t));
    if (segmentFileOffsets) {
      memcpy(newOffsets, segmentFileOffsets, _segmentCount * sizeof(uint64_t));
      free(segmentFileOffsets);
    }
    segmentFileOffsets = newOffsets;
    _segmentCount = newCount;
  }
  segmentFileOffsets[segmentIndex] = offset;
}

- (NSData *)fixupDataWithSegmentCount:(int)segmentCount {
  NSMutableData *data = [NSMutableData data];

  // 1. Build symbol pool and imports table
  NSMutableData *symbolPool = [NSMutableData data];
  NSMutableDictionary *symbolToOffset = [NSMutableDictionary dictionary];

  // Always start pool with a null byte (or two, as seen in some headers)
  uint8_t zero = 0;
  [symbolPool appendBytes:&zero length:1];

  for (MPWChainedImport *imp in imports) {
    if (!symbolToOffset[imp.symbolName]) {
      symbolToOffset[imp.symbolName] = @(symbolPool.length);
      const char *name = [imp.symbolName UTF8String];
      [symbolPool appendBytes:name length:strlen(name) + 1];
    }
  }

  // 2. Prepare Header
  struct dyld_chained_fixups_header header = {0};
  header.fixups_version = 0;
  header.imports_format = DYLD_CHAINED_IMPORT;
  header.symbols_format = 0; // uncompressed
  header.imports_count = (uint32_t)imports.count;

  // We'll fill offsets later
  [data appendBytes:&header length:sizeof(header)];

  // 3. Starts info
  header.starts_offset = (uint32_t)data.length;
  uint32_t seg_info_offsets_size = sizeof(uint32_t) * segmentCount;
  struct dyld_chained_starts_in_image *starts_in_image =
      calloc(1, sizeof(uint32_t) + seg_info_offsets_size);
  starts_in_image->seg_count = segmentCount;

  // We need to keep track of dyld_chained_starts_in_segment for each segment
  // that has fixups
  NSMutableDictionary *segIdxToFixups = [NSMutableDictionary dictionary];
  for (MPWChainedFixup *f in fixups) {
    NSMutableArray *segFixups = segIdxToFixups[@(f.segmentIndex)];
    if (!segFixups) {
      segFixups = [NSMutableArray array];
      segIdxToFixups[@(f.segmentIndex)] = segFixups;
    }
    [segFixups addObject:f];
  }

  NSMutableData *startsPool = [NSMutableData data];
  for (int i = 0; i < segmentCount; i++) {
    NSArray *segFixups = segIdxToFixups[@(i)];
    if (segFixups.count > 0) {
      starts_in_image->seg_info_offset[i] =
          (uint32_t)(sizeof(uint32_t) + seg_info_offsets_size +
                     startsPool.length);

      // Build dyld_chained_starts_in_segment
      // We assume all fixups in a segment fit on a few pages.
      // For now, let's find the max page index
      uint32_t maxPage = 0;
      for (MPWChainedFixup *f in segFixups) {
        uint32_t page = (uint32_t)(f.offset / self.pageSize);
        if (page > maxPage)
          maxPage = page;
      }

      uint32_t pageCount = maxPage + 1;
      uint32_t segStartsSize = sizeof(struct dyld_chained_starts_in_segment) +
                               (pageCount - 1) * sizeof(uint16_t);
      struct dyld_chained_starts_in_segment *segStarts =
          calloc(1, segStartsSize);
      segStarts->size = segStartsSize;
      segStarts->page_size = (uint16_t)self.pageSize;
      segStarts->pointer_format = DYLD_CHAINED_PTR_64_OFFSET;
      if (i < _segmentCount) {
        segStarts->segment_offset = segmentFileOffsets[i];
      }
      segStarts->page_count = (uint16_t)pageCount;

      // Initialize all as NONE (0xFFFF)
      for (int p = 0; p < pageCount; p++)
        segStarts->page_start[p] = DYLD_CHAINED_PTR_START_NONE;

//      NSLog(@"MPWChainedFixupWriter: Segment %d has %lu fixups, %d pages, "
//            @"segStartsSize %d",
//            i, (unsigned long)segFixups.count, pageCount, segStartsSize);

      // For now, we only support ONE fixup per page for simplicity (no chain
      // linking yet) Or we assume they are already sorted. Actually, we need to
      // sort them by offset.
      NSArray *sortedFixups = [segFixups
          sortedArrayUsingComparator:^NSComparisonResult(MPWChainedFixup *a,
                                                         MPWChainedFixup *b) {
            return a.offset < b.offset ? NSOrderedAscending
                                       : NSOrderedDescending;
          }];

      for (int f_idx = 0; f_idx < sortedFixups.count; f_idx++) {
        MPWChainedFixup *f = sortedFixups[f_idx];
        uint32_t page = (uint32_t)(f.offset / self.pageSize);
        uint16_t page_offset = (uint16_t)(f.offset % self.pageSize);

        if (segStarts->page_start[page] == DYLD_CHAINED_PTR_START_NONE) {
          segStarts->page_start[page] = page_offset;
        }

        // Calculate 'next' for the fixup at this location
        uint16_t next_offset = 0;
        if (f_idx + 1 < sortedFixups.count) {
          MPWChainedFixup *next_f = sortedFixups[f_idx + 1];
          if (next_f.offset / self.pageSize == page) {
            next_offset = (uint16_t)(next_f.offset - f.offset);
          }
        }
        f.next = next_offset;
      }

      [startsPool appendBytes:segStarts length:segStartsSize];
      free(segStarts);
    } else {
      starts_in_image->seg_info_offset[i] = 0;
    }
  }

  [data appendBytes:starts_in_image
             length:sizeof(uint32_t) + seg_info_offsets_size];
  [data appendData:startsPool];
  free(starts_in_image);

  // 4. Imports Table
  header.imports_offset = (uint32_t)data.length;
  for (MPWChainedImport *imp in imports) {
    struct dyld_chained_import entry = {0};
    entry.lib_ordinal = (uint32_t)imp.dylibOrdinal;
    entry.name_offset = [symbolToOffset[imp.symbolName] unsignedIntValue];
    [data appendBytes:&entry length:sizeof(entry)];
  }

  // 5. Symbols Pool
  header.symbols_offset = (uint32_t)data.length;
  [data appendData:symbolPool];

  // 6. Update Header
  [data replaceBytesInRange:NSMakeRange(0, sizeof(header)) withBytes:&header];

  return data;
}

- (uint64_t)bind64Bits:(int)ordinal next:(int)next {
  struct dyld_chained_ptr_64_bind entry = {0};
  entry.ordinal = (uint32_t)ordinal;
  entry.addend = 0;
  entry.reserved = 0;
  entry.next = (uint32_t)(next / 4); // 4-byte stride
  entry.bind = 1;
  uint64_t val;
  memcpy(&val, &entry, 8);
  return val;
}

- (uint64_t)rebase64Bits:(uint64_t)target next:(int)next {
  // DYLD_CHAINED_PTR_64_REBASE format:
  // target:36, high8:8, reserved:7, next:12, bind:1 (bind=0 for rebase)
  struct dyld_chained_ptr_64_rebase entry = {0};
  entry.target = target & 0x0FFFFFFFFULL; // 36 bits = 64GB max
  entry.high8 = (target >> 56) & 0xFF;    // high 8 bits
  entry.reserved = 0;
  entry.next = (uint32_t)(next / 4);      // 4-byte stride
  // bind = 0 is implicit (it's 0 by default)
  uint64_t val;
  memcpy(&val, &entry, 8);
  return val;
}

- (NSArray<MPWChainedFixup *> *)fixupsForSegment:(int)segmentIndex {
  NSMutableArray *result = [NSMutableArray array];
  for (MPWChainedFixup *f in fixups) {
    if (f.segmentIndex == segmentIndex) {
      [result addObject:f];
    }
  }
  return [result sortedArrayUsingComparator:^NSComparisonResult(
                     MPWChainedFixup *a, MPWChainedFixup *b) {
    return a.offset < b.offset ? NSOrderedAscending : NSOrderedDescending;
  }];
}

- (void)dealloc {
  [imports release];
  [fixups release];
  if (segmentFileOffsets)
    free(segmentFileOffsets);
  [super dealloc];
}

@end
