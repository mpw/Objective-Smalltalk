//
//  MPWInstanceVariable.m
//  Arch-S
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWInstanceVariable.h"


@implementation MPWInstanceVariable

objectAccessor( NSString, name, setName )
objectAccessor( NSString, type, setType )
longAccessor( offset, setOffset )

-initWithName:(NSString*)newName offset:(int)newOffset type:(NSString*)newType
{
	self=[super init];
	[self setName:newName];
	[self setOffset:newOffset];
	[self setType:newType];
	return self;
}

#define pointerToVarInObject( anObject )  ((id*)(((char*)anObject) + offset))


-valueInContext:anObject
{
	id result=nil;
	if ( anObject ) {
//        NSLog(@"ivar %@ get value at offset: %ld",name,offset);
		result= *pointerToVarInObject( anObject );
	}
	return result;
}

-(void)setValue:newValue inContext:anObject
{
	id *ptr = pointerToVarInObject( anObject );
//   NSLog(@"ivar %@ set Value: %@ at offset: %ld",name,newValue,offset);
	if ( anObject &&  *ptr != newValue ) {
		[newValue retain];
		[*ptr release];
		*ptr = newValue;
	}
}

-typeStringForTypeName:(NSString*)aType
{
    if ( aType.length == 1)  {
        return aType;
    }
    if ( [aType isEqual:@"int"] ) {
        return @"i";
    } else    if ( [aType isEqual:@"bool"] ) {
        return @"l";
    } else    if ( [aType isEqual:@"float"] ) {
        return @"f";
    } else    if ( [aType isEqual:@"void"] ) {
        return @"v";
    } else {
        return @"@";
    }
}

-(NSString*)objcType
{
    return [self typeStringForTypeName:[self type]];
}

-(void)dealloc
{
	[name release];
	[type release];
	[super dealloc];
}

@end
