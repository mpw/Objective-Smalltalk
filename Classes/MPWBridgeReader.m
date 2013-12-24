//
//  MPWBridgeReader.m
//  MPWXmlKit
//
//  Created by Marcel Weiher on 6/4/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWBridgeReader.h"
#import <MPWFoundation/AccessorMacros.h>
#import <Foundation/Foundation.h>
#import "MPWEvaluator.h"
#include <dlfcn.h>


@implementation MPWFallbackBridgeReader

idAccessor( context ,setContext )

-initWithContext:aContext
{
	self=[super init];
	[self setContext:aContext];
	return self;
}

+(void)parseBridgeDict:aDict forContext:aContext
{
	id pool=[NSAutoreleasePool new];
	id reader = [[[self alloc] initWithContext:aContext] autorelease];
	[reader parse:aDict];
	[pool release];
}


-(void)parserDidStartDocument:aParser {}
-(void)parserDidEndDocument:aParser {}
-(void)parser:aParser didEndElement:elemName namespaceURI:uri qualifiedName:qname {} 

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ( [elementName isEqual:@"enum"] ) {
		[context bindValue:[NSNumber numberWithInt:[[attributeDict objectForKey:@"value"] intValue]] toVariableNamed:[attributeDict objectForKey:@"name"]];
	} else if ( [elementName isEqual:@"constant"] ) {
		if ( [[attributeDict objectForKey:@"type"] isEqual:@"@"] ) {
			char symbol[256]="";
			id name = [attributeDict objectForKey:@"name"];
			[name getCString:symbol maxLength:254 encoding:NSASCIIStringEncoding];
			symbol[ [name length] ] =0;
			
			id* ptr=dlsym( RTLD_DEFAULT, symbol );
			if ( ptr && *ptr )  {
				[context bindValue:*ptr toVariableNamed:name];
			}
		}
	}
}

-parse:xmlData
{
	Class parserClass = NSClassFromString(@"MPWXmlParser");
	
	if ( !parserClass ) {
		parserClass=[NSXMLParser class];

	} 
	
	id parser = [[[parserClass alloc] initWithData:xmlData] autorelease];
	[parser setDelegate:self];
	[parser parse];
	return nil;
}

-(void)dealloc
{
	[context release];
	[super dealloc];
}

@end

@implementation NSBundle(bridgeSupport)

-bridgeSupportFile
{
	NSArray *paths;
	
	paths = [self pathsForResourcesOfType:@"bridgesupport" inDirectory:@"BridgeSupport"];
	return [NSData dataWithContentsOfFile:[paths lastObject]];
}

@end


@implementation MPWEvaluator(loadFramework)

-loadFramework:(NSString*)frameworkName
{
	Class readerClass = NSClassFromString(@"MPWBridgeReader");
	id bundle=[NSBundle loadFramework:frameworkName];
	id bridgeSupportFile = [bundle bridgeSupportFile];
	if (!readerClass) {
		readerClass=[MPWFallbackBridgeReader class];
	}
	[readerClass parseBridgeDict:bridgeSupportFile forContext:self];
	return bundle;
}

-(BOOL)dlopen:(NSString*)name
{
    void *ptr=dlopen([name fileSystemRepresentation], RTLD_NOW);
    return ptr != NULL;
}

@end

