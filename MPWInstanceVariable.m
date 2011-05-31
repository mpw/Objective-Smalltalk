//
//  MPWInstanceVariable.m
//  MPWTalk
//
//  Created by Marcel Weiher on 20/07/2005.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MPWInstanceVariable.h"


@implementation MPWInstanceVariable

objectAccessor( NSString, name, setName )
objectAccessor( NSString, type, setType )
intAccessor( offset, setOffset )

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
		result= *pointerToVarInObject( anObject );
	}
	return result;
}

-(void)setValue:newValue inContext:anObject
{
	id *ptr = pointerToVarInObject( anObject );
	if ( anObject &&  *ptr != newValue ) {
		[newValue retain];
		[*ptr release];
		*ptr = newValue;
	}
}

-(void)dealloc
{
	[name release];
	[type release];
	[super dealloc];
}

@end
