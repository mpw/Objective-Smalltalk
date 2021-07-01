//
//  MPWInstanceVariable.m
//  Arch-S
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWInstanceVariable.h"
#import "STTypeDescriptor.h"

@implementation MPWInstanceVariable

longAccessor( offset, setOffset )

-initWithName:(NSString*)newName offset:(int)newOffset type:(STTypeDescriptor*)newType
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

-(NSString*)typeName
{
    return [self.type name];
}

-(NSString*)objcType
{
    return [NSString stringWithFormat:@"%c",self.type.objcTypeCode];
}

-(void)dealloc
{
	[super dealloc];
}

@end
