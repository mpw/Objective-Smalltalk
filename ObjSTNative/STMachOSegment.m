//
//  MPWMachOSegment.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.02.26.
//

#import "STMachOSegment.h"
#import "MPWMachOSection.h"

@implementation STMachOSegment

- (instancetype)initWithSegmentCommand:(struct segment_command_64*)segmentCommand 
                                data:(NSData*)data 
                              sections:(NSArray<MPWMachOSection*>*)sections
{
    self = [super init];
    if (self) {
        _segmentCommand = segmentCommand;
        _sections = [sections copy];
        
        // Extract segment name (16-byte fixed field)
        _name = [[NSString stringWithUTF8String:segmentCommand->segname] retain];
    }
    return self;
}

- (void)dealloc
{
    [_name release];
    [_sections release];
    [super dealloc];
}

- (long)vmaddr
{
    return self.segmentCommand->vmaddr;
}

- (long)vmsize
{
    return self.segmentCommand->vmsize;
}

- (long)fileoff
{
    return self.segmentCommand->fileoff;
}

- (long)filesize
{
    return self.segmentCommand->filesize;
}

- (MPWMachOSection*)sectionNamed:(NSString*)sectionName
{
    for (MPWMachOSection *section in self.sections) {
        if ([section.sectionName isEqualToString:sectionName]) {
            return section;
        }
    }
    return nil;
}

- (BOOL)containsFileOffset:(long)offset
{
    return offset >= self.fileoff && offset < self.fileoff + self.filesize;
}

- (BOOL)containsVMAddress:(long)address
{
    return address >= self.vmaddr && address < self.vmaddr + self.vmsize;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<MPWMachOSegment: %@ vmaddr=0x%lx vmsize=0x%lx fileoff=%ld filesize=%ld sections=%lu>",
            self.name, self.vmaddr, self.vmsize, self.fileoff, self.filesize, (unsigned long)self.sections.count];
}

@end
