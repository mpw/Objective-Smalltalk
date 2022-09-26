//
//  MPWJittableData.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 26.09.22.
//

#import "MPWJittableData.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MPWJittableData
{
    unsigned char *bytes;
    long capacity;
    long length;
}

-(instancetype)initWithCapacity:(long)initialCapacity
{
    long pagesize_mask=getpagesize()-1;
    self=[super init];
    initialCapacity = (initialCapacity + pagesize_mask ) & ~pagesize_mask;
    if ( self ) {
        bytes=mmap(NULL, initialCapacity, PROT_WRITE|PROT_READ, MAP_ANON|MAP_PRIVATE, 0, 0);
        if (!bytes) {
            return nil;
        }
        capacity=initialCapacity;
        length=0;
    }
    return self;
}

-(const void*)bytes
{
    return bytes;
}

-(void*)mutableBytes
{
    return bytes;
}

-(void)appendBytes:(const void*)newBytes length:(long)newLength
{
    if ( newLength + length < capacity ) {
        memcpy(bytes+length, newBytes, newLength);
        length+=newLength;
    } else {
        [NSException raise:@"outofbounds" format:@"writing %ld bytes at length %ld would exceed capacity %ld",newLength,length,capacity];
    }
}

-(void)makeExecutable
{
    int retcode = mprotect(bytes, capacity, PROT_READ|PROT_EXEC);
    if (retcode != 0) {
        NSLog(@"return of mprotect to make executable: %d errno: %d",retcode,errno);
    }
}

-(void)makeWritable
{
    int retcode = mprotect(bytes, capacity, PROT_READ|PROT_WRITE);
    if (retcode != 0) {
        NSLog(@"return of mprotect to make writable: %d errno: %d",retcode,errno);
    }
}

-(long)length
{
    return length;
}

-(long)capacity
{
    return capacity;
}

-(void)dealloc
{
    if ( bytes ) {
        munmap( bytes, capacity );
        bytes=NULL;
    }
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWJittableData(testing) 

+(void)testCanWriteSomeBytes
{
    MPWJittableData *data=[[[self alloc] initWithCapacity:4096] autorelease];
    [data appendBytes:"Hello World!" length:12];
    EXPECTTRUE( strncmp( [data bytes],"Hello World!",12)==0, @"written bytes match");
}

+(void)testCanStreamBytes
{
    MPWJittableData *data=[[[self alloc] initWithCapacity:4096] autorelease];
    MPWByteStream *s=[MPWByteStream streamWithTarget:data];
    [s writeString:@"Hello World!"];
    EXPECTTRUE( strncmp( [data bytes],"Hello World!",12)==0, @"written bytes match");

}

+(NSArray*)testSelectors
{
   return @[
       @"testCanWriteSomeBytes",
       @"testCanStreamBytes",
			];
}

@end
