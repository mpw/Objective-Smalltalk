//
//  MPWByteStreamWithSymbols.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.10.22.
//

#import "MPWByteStreamWithSymbols.h"

@implementation MPWByteStreamWithSymbols

-(void)addGlobalSymbol:(NSString*)symbol
{
    [self.symbolWriter addGlobalSymbol:symbol atOffset:(int)[self length]];
}

-(void)addRelocationEntryForSymbol:(NSString*)symbol
{
    NSLog(@"relocationWriter: %@  addRelocationSymbol: %@",self.relocationWriter,symbol);
    [self.relocationWriter addRelocationEntryForSymbol:symbol atOffset:(int)[self length]];
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
