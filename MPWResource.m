//
//  MPWResource.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWResource.h"


@implementation MPWResource

objectAccessor( NSData *, rawData, setRawData )
objectAccessor( NSString*, mimetype, setMimetype )
idAccessor( _value, setValue )
idAccessor( source, setSource )

-convertRawDataToObject
{
	if ( [[self mimetype] hasPrefix:@"image/"] ) {
		return [NSClassFromString(@"NSBitmapImageRep") imageRepWithData:[self rawData]];
	}
	return nil;
}


-value
{
	id value=[self _value];
	if ( !value ) {
		[self setValue:value=[self convertRawDataToObject]];
	}
	return value;
}

-(void)forwardInvocation:(NSInvocation*)invocation
{
	if ( [self value] ) {
		[invocation invokeWithTarget:[self value]];
	} else if ( [self rawData] ) {
		[invocation invokeWithTarget:[self rawData]];
	}
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
	NSMethodSignature *sig=[super methodSignatureForSelector:selector];
	if ( !sig ) {
		sig=[[self value] methodSignatureForSelector:selector];
	}
	if ( !sig ) {
		sig=[[self rawData] methodSignatureForSelector:selector];
	}
	return sig;
}

-(BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] ||
	[[self value] respondsToSelector:aSelector] ||
	[[self rawData]  respondsToSelector:aSelector];
}


-description
{
	if ( [self value] ) {
		return [[self value] description];
	} else {
		return [[self rawData] description];
	}
}

-(void)writeOnByteStream:aStream
{
	if ( [self value] ) {
		return [[self value] writeOnByteStream:aStream];
	} else {
		return [[self rawData] writeOnByteStream:aStream];
	}
}

-(NSString*)name 
{
	return [[[self source] path] lastPathComponent];
}

-(NSString*)extension  
{
	return [[self name] pathExtension];
}

-(void)dealloc
{
	[source release];
	[rawData release];
	[_value release];
	[mimetype release];
	[super dealloc];
}

@end
