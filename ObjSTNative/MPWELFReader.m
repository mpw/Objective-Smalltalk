//
//  MPWELFReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 29.05.23.
//

#import "MPWELFReader.h"
#include "elf.h"

@interface MPWELFReader()

@property (nonatomic, strong) NSData *elfData;

@end

@implementation MPWELFReader

-initWithData:(NSData*)newData
{
    self=[super init];
    self.elfData=newData;
    return self;
}

-(const void*)bytes
{
    return [[self elfData] bytes];
}

-(Elf64_Ehdr*)header
{
    return (Elf64_Ehdr*)[self bytes];
}



@end


#import <MPWFoundation/MPWFoundation.h>

@implementation MPWELFReader(testing) 

+(instancetype)readerForTestFile:(NSString*)name
{
    NSData *addmacho=[self frameworkResource:name category:@"elf-o"];
    MPWELFReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    return reader;
}

+(void)testCanReadElfHeader
{
    MPWELFReader *reader=[self readerForTestFile:@"empty-function"];
    EXPECTNOTNIL(reader.elfData, @"elf data");
    EXPECTTRUE(!strncmp([reader bytes],ELFMAG ,4), @"elf magic");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCanReadElfHeader",
			];
}

@end
