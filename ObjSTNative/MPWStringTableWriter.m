//
//  MPWStringTableWriter.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 06.05.24.
//

#import "MPWStringTableWriter.h"
#import <MPWFoundation/MPWFoundation.h>

@interface MPWStringTableWriter()

@property (nonatomic, strong) NSMutableDictionary *stringTableOffsets;
@property (nonatomic, strong) MPWByteStream *stringTableWriter;


@end

@implementation MPWStringTableWriter

+(instancetype)writer
{
    return [[[self alloc] init] autorelease];
}

-(instancetype)init
{
    self=[super init];
    self.stringTableOffsets = [NSMutableDictionary dictionary];
    self.stringTableWriter = [MPWByteStream stream];
    [self.stringTableWriter appendBytes:"" length:1];
    return self;
}

-(int)stringTableOffsetOfString:(NSString*)theString
{
    int offset = [self.stringTableOffsets[theString] intValue];
    if ( !offset ) {
        offset=(int)[self.stringTableWriter length];
        [self.stringTableWriter writeObject:theString];
        [self.stringTableWriter appendBytes:"" length:1];
        self.stringTableOffsets[theString]=@(offset);
    }
    return offset;
}

-(long)length
{
    return self.stringTableWriter.length;
}

-(NSData*)data
{
    return (NSData*)self.stringTableWriter.target;
}

-(void)dealloc
{
    [_stringTableOffsets release];
    [_stringTableWriter release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStringTableWriter(testing) 

+(void)testCanWriteStringsToStringTable
{
    MPWStringTableWriter *writer = [[self new] autorelease];
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
