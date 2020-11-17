//
//  MPWResource.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/25/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWResource.h"

@interface NSObject(imageRepWithData)

+imageRepWithData:(NSData*)data;

@end


@implementation MPWResource

objectAccessor( NSData, rawData, setRawData )
objectAccessor( NSString, MIMEType, setMIMEType )
objectAccessor( NSError, error, setError)
idAccessor( _value, setValue )
idAccessor( source, setSource )

-convertRawDataToObject
{
	if ( [[self MIMEType] hasPrefix:@"image/"] ) {
		return [NSClassFromString(@"NSBitmapImageRep") imageRepWithData:[self rawData]] ;
	} else if ( ([[self MIMEType] hasPrefix:@"application/json"] || [[self MIMEType] hasPrefix:@"text/javascript"]) && NSClassFromString(@"NSJSONSerialization")) {
		return [NSClassFromString(@"NSJSONSerialization") JSONObjectWithData:[self rawData] options:0 error:NULL] ;
	}  else if ( [[self extension] isEqual:@"newsplist"] ||
                [[self extension] isEqual:@"plist"] ) {
        return [NSPropertyListSerialization propertyListWithData:[self rawData] options:0 format:0 error:NULL];
        
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
	if ( [self value] && [[self value] respondsToSelector:[invocation selector]]) {
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

-(id)valueForKey:(NSString *)key
{
    if ( [self value] ) {
        return [[self value] valueForKey:key];
    } else {
        return [[self rawData] valueForKey:key];
    }
}

-(NSString *)stringValue
{
	if ( [self value] ) {
		return [[self value] stringValue];
	} else {
		return [[self rawData] stringValue];
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

-(void)writeToURL:(NSURL*)url atomically:(BOOL)atomically
{
    [[self rawData] writeToURL:url atomically:atomically];
}

-(NSString*)name 
{
	return [[[self source] path] lastPathComponent];
}

-(NSString*)extension  
{
	return [[self name] pathExtension];
}

-(NSData *)asData
{
    return [self rawData];
}

-(void)dealloc
{
	[source release];
	[rawData release];
	[_value release];
	[MIMEType release];
    [error release];
	[super dealloc];
}

@end
