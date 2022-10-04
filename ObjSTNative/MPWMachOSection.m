//
//  MPWMachOSection.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.10.22.
//

#import "MPWMachOSection.h"
#import <mach-o/loader.h>

@interface MPWMachOSection()

@property (nonatomic, strong) NSData *machoData;

@end

@implementation MPWMachOSection
{
    const struct section_64 *sectionHeader;
}

-(instancetype)initWithSectionHeader:(const void*)headerptr inMacho:(NSData*)bytes
{
    self=[super init];
    if ( self ) {
        sectionHeader=headerptr;
        self.machoData = bytes;
    }
    return self;
}

-(NSData*)sectionData
{
    return [self.machoData subdataWithRange:NSMakeRange(sectionHeader->offset,sectionHeader->size)];
}



-(void)dealloc
{
    [_machoData release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMachOSection(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
