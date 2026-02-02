//
//  MPWMachOSegment.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 02.02.26.
//

#import <Foundation/Foundation.h>
#import <mach-o/loader.h>

NS_ASSUME_NONNULL_BEGIN

@class MPWMachOSection;

@interface MPWMachOSegment : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) struct segment_command_64 *segmentCommand;
@property (nonatomic, readonly) NSArray<MPWMachOSection*> *sections;

@property (nonatomic, readonly) long vmaddr;
@property (nonatomic, readonly) long vmsize;
@property (nonatomic, readonly) long fileoff;
@property (nonatomic, readonly) long filesize;

- (instancetype)initWithSegmentCommand:(struct segment_command_64*)segmentCommand 
                                data:(NSData*)data 
                              sections:(NSArray<MPWMachOSection*>*)sections;

- (MPWMachOSection* _Nullable)sectionNamed:(NSString*)sectionName;
- (BOOL)containsFileOffset:(long)offset;
- (BOOL)containsVMAddress:(long)address;

@end

NS_ASSUME_NONNULL_END