//
//  MPWELFSymbolTable.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 04.05.24.
//

#import "MPWELFSymbolTable.h"
#import "MPWELFReader.h"
#import "elf.h"


@implementation MPWELFSymbolTable

-(Elf64_Sym*)symbols
{
    return (Elf64_Sym*)([self.reader.elfData bytes] + [self sectionOffset]);
}



-(NSString*)symbolNameAtIndex:(int)anIndex
{
    return [self.reader stringAtOffset:[self symbols][anIndex].st_name];
}


-(int)symbolInfoAtIndex:(int)anIndex
{
    return [self symbols][anIndex].st_info;
}

-(int)symbolTypeAtIndex:(int)anIndex
{
    return ELF64_ST_TYPE([self symbols][anIndex].st_info);
}

-(long)symbolValueAtIndex:(int)anIndex
{
    return [self symbols][anIndex].st_value;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWELFSymbolTable(testing) 



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
