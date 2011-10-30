//
//  MPWSchemeHttpServer.m
//  
//
//  Created by Marcel Weiher on 10/24/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWSchemeHttpServer.h"
#import <MPWSideWeb/MPWHTTPServer.h>
#import <MPWSideWeb/MPWPOSTProcessor.h>
#import "MPWScheme.h"
#import "MPWBinding.h"

@implementation MPWSchemeHttpServer

objectAccessor(MPWHTTPServer, server, setServer )
objectAccessor(MPWScheme, scheme, setScheme)

-(MPWBinding*)identifierForString:(NSString*)uriString
{
    return [[self scheme] bindingForName:uriString inContext:nil]; 
}

-(NSData*)get:(NSString*)uri parameters:(NSDictionary*)params
{
    return [[[self identifierForString:uri] value] asData];
}

-(id)deserializeData:(NSData*)inputData at:(MPWBinding*)aBinding
{
    return inputData;
}

-(NSData*)put:(NSString *)uri data:putData parameters:(NSDictionary*)params
{    id identifier=[self identifierForString:uri];

    [identifier bindValue:[self deserializeData:putData at:identifier]];
    return [uri asData];
}

-(NSData*)post:(NSString*)uri parameters:(MPWPOSTProcessor*)postData
{
    return [[[self identifierForString:uri] postWithDictionary:[postData values]] asData];
}



-(void)dealloc
{
    [scheme release];
    [server release];
    [super dealloc];
}
-(void)setupWebServer
{
    [self setServer:[[[MPWHTTPServer alloc] init] autorelease]];
    [[self server] setDelegate:self];
    [[self server] setPort:51000];
    [[self server] setTypes:[NSArray arrayWithObjects:@"_http._tcp.",@"_methods._tcp.",nil]];
    [[self server] start:nil];
    
}

@end
