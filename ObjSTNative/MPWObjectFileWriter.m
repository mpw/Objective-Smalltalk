//
//  MPWObjectFileWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import "MPWObjectFileWriter.h"
#import "MPWStringTableWriter.h"

@interface MPWObjectFileWriter()

@property (nonatomic, strong) MPWStringTableWriter *stringTableWriter;

@end

@implementation MPWObjectFileWriter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.stringTableWriter = [MPWStringTableWriter writer];
    return self;
}

-(int)stringTableOffsetOfString:(NSString*)theString
{
    return [self.stringTableWriter stringTableOffsetOfString:theString];
}



-(void)dealloc
{
    [_stringTableWriter release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWObjectFileWriter(testing) 

+(void)testCanWriteStringsToStringTable
{
    MPWObjectFileWriter *writer = [self stream];
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_sub"],6,@"offset");
    INTEXPECT( [writer stringTableOffsetOfString:@"_add"],1,@"repeat");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteStringsToStringTable",
			];
}

@end
