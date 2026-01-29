//
//  MPWMachOWriter+Private.h
//  ObjSTNative
//
//  Private interface for subclasses
//

#import "MPWMachOWriter.h"

@class MPWMachOSectionWriter;

@interface MPWMachOWriter()

@property (nonatomic, assign) int numLoadCommands;
@property (nonatomic, assign) int cputype;
@property (nonatomic, assign) int filetype;
@property (nonatomic, assign) int loadCommandSize;
@property (nonatomic, assign) long totalSegmentSize;

@property (nonatomic, strong) MPWMachOSectionWriter *textSectionWriter;
@property (nonatomic, strong) NSMutableArray<MPWMachOSectionWriter*>* sectionWriters;

-(NSArray<MPWMachOSectionWriter*>*)activeSectionWriters;
-(int)segmentOffset;
-(int)numSymbols;
-(int)symbolTableSize;
-(void)writePlatformLoadCommand;
-(void)writeSymbolTable;
-(void)writeStringTable;
-(void)writeSymbolTableData;  // Writes symtab data without offset assertion
-(void)adjustSymtabEntries;   // Adjust symbol addresses based on section addresses

@end
