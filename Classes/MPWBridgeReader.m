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
#import "STEvaluator.h"
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
        NSString *key=[attributeDict objectForKey:@"name"];
        NSString *value=[attributeDict objectForKey:@"value64"];
        if ( !value ) {
            value=[attributeDict objectForKey:@"value"];
        }
		[context bindValue:@([value intValue]) toVariableNamed:key];
	} else if ( [elementName isEqual:@"constant"] ) {
		if ( [[attributeDict objectForKey:@"type"] isEqual:@"@"] ) {
			char symbol[256]="";
			id name = [attributeDict objectForKey:@"name"];
            long symlen=[name length];
            NSAssert(symlen < 254, @"symlen %ld > 254",symlen);
			[name getCString:symbol maxLength:254 encoding:NSASCIIStringEncoding];
			symbol[ symlen ] =0;
			
			id* ptr=dlsym( RTLD_DEFAULT, symbol );
			if ( ptr && *ptr )  {
				[context bindValue:*ptr toVariableNamed:name];
			}
		}
	}
}

-(BOOL)parse:(NSData*)xmlData
{
	Class parserClass = NSClassFromString(@"MPWXmlParser");
	
	if ( !parserClass ) {
		parserClass=[NSXMLParser class];

	} 
	
	NSXMLParser* parser = [[[parserClass alloc] initWithData:xmlData] autorelease];
	[parser setDelegate:(id <NSXMLParserDelegate>)self];
	[parser parse];
	return YES;
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



-(BOOL)loadFrameworkAndSymbols:aContext
{
    if ([self load] ) {
        Class readerClass = NSClassFromString(@"MPWBridgeReader");
        id bridgeSupportFile = [self bridgeSupportFile];
        if (!readerClass) {
            readerClass=[MPWFallbackBridgeReader class];
        }
        [readerClass parseBridgeDict:bridgeSupportFile forContext:aContext];
        return YES;
    }
    return NO;
}

@end


@implementation STEvaluator(loadFramework)



-loadFramework:(NSBundle*)bundle
{
    Class readerClass = NSClassFromString(@"MPWBridgeReader");
    id bridgeSupportFile = [bundle bridgeSupportFile];
    [bundle load];
    if (!readerClass) {
        readerClass=[MPWFallbackBridgeReader class];
    }
    [readerClass parseBridgeDict:bridgeSupportFile forContext:self];
    return bundle;
}

-loadFrameworkNamed:(NSString*)frameworkName
{
    id bundle=[NSBundle loadFramework:frameworkName];
    return [self loadFramework:bundle];
}

-(void*)dlopen:(NSString*)name
{
    void *ptr=dlopen([name fileSystemRepresentation], RTLD_NOW);
    return ptr;
}

-(int)dlclose:(void*)handle
{
    return dlclose(handle);
}


@end

@implementation NSBundle(frameworkLoading)


-loadIn:aContext
{
    return [aContext loadFramework:self];
}

@end
