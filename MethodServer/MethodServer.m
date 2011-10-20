//
//  MethodServer.m
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MethodServer.h"
#import <MPWSideWeb/MPWHTTPServer.h>
#import <MPWSideWeb/MPWPOSTProcessor.h>
#import "MPWStCompiler.h"

@implementation MethodServer

objectAccessor(MPWStCompiler, interpreter, setInterpreter)
objectAccessor(MPWHTTPServer, server, setServer)

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setup
{
    [self setInterpreter:[[[MPWStCompiler alloc] init] autorelease]];
    [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
    [[self interpreter] bindValue:self toVariableNamed:@"appDelegate"];
    NSLog(@"PATH: %@",[MPWStCompiler evaluate:@"env:PATH"]);
    [self defineMethodsInExternalDict:[self externalMethodsDict]];
//    NSLog(@"the answer: %d",[self theAnswer]);
    [self setupWebServer];

}

-(NSData*)methodList
{
    NSDictionary *methods=[[self interpreter] externalScriptDict];
    return [[methods description] asData];
}


-(NSData*)get:(NSString*)uri parameters:(NSDictionary*)params
{
    if ( [uri hasPrefix:@"/methods"] ) {
        return [self methodList];
    } else if ( [uri hasPrefix:@"/theAnswer"] ) {
        return [[NSString stringWithFormat:@"the answer: %d",[self theAnswer]] asData];
    } else {
        return [uri asData];
    }
}

-eval:(NSString*)aString
{
    id result=@"";
    @try {
        result = [[self interpreter] evaluateScriptString:aString];
    } @catch ( id e ) {
        NSLog(@"evaluating '%@' threw '%@'",aString,e);
    }
    NSLog(@"result: %@",result);
    
    return result;
}

-(NSData*)post:(NSString*)uri parameters:(MPWPOSTProcessor*)postData
{
    NSLog(@"POST to %@",uri);
    if ( [uri hasPrefix:@"/methods"] ) {
        NSData *methodData=[[postData values] objectForKey:@"methods"];
        [self defineMethodsInExternalDict:[self dictionaryFromData:methodData]];
        return [@"Defined some methods\n" asData];
    } else  if ( [uri hasPrefix:@"/eval"] ) {
        NSData *evalData=[[postData values] objectForKey:@"eval"];
        NSString *evalString = [evalData stringValue];
        NSLog(@"should eval: %@",evalString);
        [self performSelectorOnMainThread:@selector(eval:) withObject:evalString waitUntilDone:YES];
        return [@"did evaluate" asData];
    }
    return [uri asData];
}


-(void)setupWebServer
{
    [self setServer:[[[MPWHTTPServer alloc] init] autorelease]];
    [[self server] setPort:51000];
    [[self server] setTypes:[NSArray arrayWithObjects:@"_http._tcp.",@"_methods._tcp.",nil]];
    [[self server] setDelegate:self];
    [[self server] start:nil];
    
}


-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
    NSLog(@"define methods: %@",dict);
    if ( dict ) {
        [[self interpreter] defineMethodsInExternalDict:dict];
    }
}

-(NSDictionary*)dictionaryFromData:(NSData*)dictData
{
    return [NSPropertyListSerialization propertyListFromData: dictData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    
}

-(NSDictionary*)externalMethodsDict
{
    NSData *dictData = [[NSBundle mainBundle] resourceWithName:@"methods" type:@"plist"];
    NSLog(@"data %p len: %d",dictData,[dictData length]);
    return [self dictionaryFromData:dictData];
}

scalarAccessor(id, delegate, setDelegate)

@end
