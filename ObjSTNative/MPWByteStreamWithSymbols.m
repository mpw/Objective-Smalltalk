//
//  MPWByteStreamWithSymbols.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import "MPWByteStreamWithSymbols.h"

@implementation MPWByteStreamWithSymbols

-(void)declareGlobalSymbol:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:(int)[self length]];
}

-(void)addRelocationEntryForSymbol:(NSString*)symbol
{
//    NSLog(@"relocationWriter: %@  addRelocationSymbol: %@",self.relocationWriter,symbol);
    [self.relocationWriter addRelocationEntryForSymbol:symbol atOffset:(int)[self length] ];
}

-(void)addRelocationEntryForSymbol:(NSString*)symbol relativeOffset:(int)offset type:(int)relocationType relative:(BOOL)relative
{
    [self.relocationWriter addRelocationEntryForSymbol:symbol atOffset:offset+(int)[self length] type:relocationType relative:relative];
}

-(void)declareExternalFunction:(NSString*)symbol
{
    [self.symbolWriter declareGlobalSymbol:symbol atOffset:0 type:0x1 section:0];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWByteStreamWithSymbols(testing) 

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
