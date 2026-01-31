//
//  MPWBindOpcodeWriter.h
//  ObjSTNative
//
//  Writes bind and rebase opcodes for Mach-O dylibs
//  Bind opcodes: for external symbol references
//  Rebase opcodes: for internal pointer fixups when loaded at different address
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

// Represents a single bind entry (external symbol reference)
@interface MPWBindEntry : NSObject
@property (nonatomic, assign) int segmentIndex;      // Which segment (0=__TEXT, 1=__DATA, etc.)
@property (nonatomic, assign) long segmentOffset;    // Offset within segment
@property (nonatomic, assign) int type;              // BIND_TYPE_POINTER, etc.
@property (nonatomic, assign) int dylibOrdinal;      // Which dylib the symbol is from (1-based, or special values)
@property (nonatomic, strong) NSString *symbolName;  // Symbol name (e.g., "_objc_msgSend")
@property (nonatomic, assign) long addend;           // Addend to add to symbol address
@end

// Represents a single rebase entry (internal pointer fixup)
@interface MPWRebaseEntry : NSObject
@property (nonatomic, assign) int segmentIndex;      // Which segment
@property (nonatomic, assign) long segmentOffset;    // Offset within segment
@property (nonatomic, assign) int type;              // REBASE_TYPE_POINTER, etc.
@end

@interface MPWBindOpcodeWriter : NSObject

// Add bind entries (external symbol references)
-(void)addBindForSymbol:(NSString*)symbol
            fromDylib:(int)dylibOrdinal
          atSegment:(int)segmentIndex
             offset:(long)offset;

-(void)addBindForSymbol:(NSString*)symbol
            fromDylib:(int)dylibOrdinal
          atSegment:(int)segmentIndex
             offset:(long)offset
             addend:(long)addend;

// Add rebase entries (internal pointer fixups)
-(void)addRebaseAtSegment:(int)segmentIndex offset:(long)offset;

// Generate opcode streams
-(NSData*)bindOpcodeData;
-(NSData*)rebaseOpcodeData;

// Convenience: bind to flat namespace lookup
-(void)addBindForSymbol:(NSString*)symbol atSegment:(int)segmentIndex offset:(long)offset;

@end

NS_ASSUME_NONNULL_END
