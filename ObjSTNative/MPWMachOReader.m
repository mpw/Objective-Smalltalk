//
//  MPWMachOReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 09.09.22.
//

#import "MPWMachOReader.h"
#import <mach-o/loader.h>

@interface MPWMachOReader()

@property (nonatomic, strong) NSData *data;

@end

@implementation MPWMachOReader

-(instancetype)initWithData:(NSData*)machodata
{
    if ( machodata ) {
        self=[super init];
        self.data = machodata;
        return self;
    } else {
        return nil;
    }
}

-(struct mach_header_64*)header
{
    return (struct mach_header_64*)[[self data] bytes];
}

-(BOOL)isHeaderValid
{
    struct mach_header_64 *header=[self header];
    return header->magic == MH_MAGIC_64;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOReader(testing) 

+(void)canIdentifyHeader
{
    NSData *addmacho=[self frameworkResource:@"add" category:@"macho"];
    MPWMachOReader *reader=[[[self alloc] initWithData:addmacho] autorelease];
    EXPECTNOTNIL(addmacho, @"got the macho");
    EXPECTTRUE([reader isHeaderValid], @"got the right header");
    NSData *notamacho = [@"Hello World!" asData];
    reader=[[[self alloc] initWithData:notamacho] autorelease];
    EXPECTFALSE([reader isHeaderValid], @"not a Mach-O header");
}

+(NSArray*)testSelectors
{
   return @[
			@"canIdentifyHeader",
			];
}

@end
