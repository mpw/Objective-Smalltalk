//
//  MPWELFSmybolTable.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.05.24.
//

#import "MPWELFSmybolTable.h"
#import "MPWELFReader.h"
#import "elf.h"


@implementation MPWELFSmybolTable

-(Elf64_Sym*)symbols
{
    return (Elf64_Sym*)([self.reader.elfData bytes] + [self sectionOffset]);
}



-(NSString*)symbolNameAtIndex:(int)anIndex
{
    return [self.reader stringAtOffset:[self symbols][anIndex].st_name];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFSmybolTable(testing) 



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
