//
//  MPWVARBinding.m
//  MPWTalk
//
//  Created by Marcel Weiher on 17.12.09.
//  Copyright 2009 Marcel Weiher. All rights reserved.
//

#import "MPWVARBinding.h"


@implementation MPWVARBinding

objectAccessor( NSString*, kvpath, setKvpath )
idAccessor( baseObject, setBaseObject )


-initWithBaseObject:newBase kvpath:newKvpath
{
	self=[super init];
	[self setKvpath:newKvpath];
	[self setBaseObject:newBase];
	return self;
	
}

-(BOOL)isBound
{
	return YES;
}

-_value
{
//	NSLog(@"var-binding: %@ in %@",kvpath, baseObject);
	return [baseObject valueForKeyPath:kvpath];
}

-(void)_setValue:newValue
{
	[baseObject setValue:newValue forKeyPath:kvpath];
}

-(void)dealloc
{
	[baseObject release];
	[kvpath release];
	[super dealloc];
}



@end
