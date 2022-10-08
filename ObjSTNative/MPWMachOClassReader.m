//
//  MPWMachOClassReader.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 08.10.22.
//

#import "MPWMachOClassReader.h"
#import "MPWMachOReader.h"
#import "MPWMachOSection.h"
#import "MPWMachOPointer.h"

@interface MPWMachOClassReader()

@property (nonatomic, strong) MPWMachOReader *reader;
@property (nonatomic, strong) MPWMachOSection *classListSection;
@end


@implementation MPWMachOClassReader

-(instancetype)initWithReader:(MPWMachOReader*)reader
{
    self=[super init];
    self.reader = reader;
    self.classListSection = [reader objcClassListSection];
    return self;
}

-(NSArray<MPWMachOPointer*>*)classes
{
    NSMutableArray *classes = [NSMutableArray array];
    for (int i=0;i<[self numberOfClasses];i++) {
        [classes addObject:[[[MPWMachOPointer alloc] initWithSection:self.classListSection relocEntryIndex:i] autorelease]];;
    }
    return classes;
}

-(int)numberOfClasses
{
    return [self.classListSection numRelocEntries];
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


+(void)testNumberOfClasses
{
    MPWMachOClassReader *reader=[MPWMachOClassReader readerForTestFile:@"two-classes"];
    INTEXPECT( reader.numberOfClasses, 2, @"number of classes");
}

+(void)testGetClassPointers
{
    MPWMachOClassReader *reader=[MPWMachOClassReader readerForTestFile:@"two-classes"];
    NSArray<MPWMachOPointer*> *classPointers = [reader classes];
    INTEXPECT( classPointers.count, 2, @"number of classes");
    IDEXPECT( classPointers[0].name, @"_OBJC_CLASS_$_SecondClass",@"First class in list");
    IDEXPECT( classPointers[1].name, @"_OBJC_CLASS_$_FirstClass",@"Last class in list");

}

+(NSArray*)testSelectors
{
   return @[
       @"testNumberOfClasses",
       @"testGetClassPointers",
			];
}

@end
