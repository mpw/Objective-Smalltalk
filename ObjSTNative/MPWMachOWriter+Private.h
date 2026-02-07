//
//  MPWMachOWriter+Private.h
//  ObjSTNative
//
//  Private interface for subclasses
//

#import "STMachOWriter.h"
#import "Mach_O_Structs.h"

@class STMachOSectionWriter;

@interface STMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;
@property (nonatomic, assign) long totalSegmentSize;

@property (nonatomic, strong) STMachOSectionWriter *textSectionWriter;
@property (nonatomic, strong) NSMutableArray<STMachOSectionWriter*>* sectionWriters;

-(NSArray<STMachOSectionWriter*>*)activeSectionWriters;
-(int)segmentOffset;
-(int)numSymbols;
-(int)symbolTableSize;
-(void)writePlatformLoadCommand;
-(void)writeSymbolTable;
-(void)writeStringTable;
-(void)writeSymbolTableData;  // Writes symtab data without offset assertion
-(void)adjustSymtabEntries;   // Adjust symbol addresses based on section addresses
-(symtab_entry*)symtabEntries;  // Access raw symtab for subclass overrides

@end
