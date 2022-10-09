//
//  MPWMachOClassReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import "MPWMachOClassReader.h"
#import "MPWMachOReader.h"
#import "MPWMachOSection.h"
#import "MPWMachORelocationPointer.h"

@interface MPWMachOClassReader()

//@property (nonatomic, strong) MPWMachOReader *reader;
@property (nonatomic, strong) MPWMachORelocationPointer *basePointer;
@end


@implementation MPWMachOClassReader

-(instancetype)initWithPointer:(MPWMachORelocationPointer*)basePointer
{
    self=[super init];
    self.basePointer = basePointer;
    return self;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOClassReader(testing) 

+(instancetype)readerForTestFile:(NSString*)testfile
{
    MPWMachOReader *machoReader=[MPWMachOReader readerForTestFile:@"two-classes"];
    MPWMachOClassReader *classreader = [[[self alloc] initWithReader:machoReader] autorelease];
    return classreader;
}

+(NSArray*)testSelectors
{
   return @[
			];
}

@end
