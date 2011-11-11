//
//  MethodServer.m
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MethodServer.h"
#import "MPWStCompiler.h"
#import "MPWMethodScheme.h"
#import "MPWBinding.h"

@implementation MethodServer

objectAccessor(MPWStCompiler, interpreter, setInterpreter)

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(id)deserializeData:(NSData*)inputData at:(MPWBinding*)aBinding
{
    if ( [[aBinding name] isEqual:@"methods"] ) {
        return [self dictionaryFromData:inputData];
    }
    return [super deserializeData:inputData at:aBinding];
}



-(void)setup
{
    [self setInterpreter:[[[MPWStCompiler alloc] init] autorelease]];
    [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
    [[self interpreter] bindValue:self toVariableNamed:@"appDelegate"];
    NSLog(@"PATH: %@",[MPWStCompiler evaluate:@"env:PATH"]);
    [self defineMethodsInExternalDict:[self externalMethodsDict]];
//    NSLog(@"the answer: %d",[self theAnswer]);
    [self setScheme:[[[MPWMethodScheme alloc] initWithInterpreter:[self interpreter]] autorelease]];
    [self setupWebServer];

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


-(NSData*)get:(NSString*)uri parameters:(NSDictionary*)params
{
    NSLog(@"uri: %@",uri);
    if ( [uri hasPrefix:@"/theAnswer"] ) {
        return [NSString stringWithFormat:@"theAnswer: %d",(int)[self theAnswer]];
    } else {
        return [super get:uri parameters:params];
    }
}

-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
    NSLog(@"define methods: %@",dict);
    if ( dict ) {
        [[self interpreter] defineMethodsInExternalDict:dict];
    }
}

-(void)setupWebServer
{
    [super setupWebServer];
    [[self server] setPort:51000];
    [[self server] setBonjourName:@"Methods"];
    [[self server] setTypes:[NSArray arrayWithObjects:@"_http._tcp.",@"_methods._tcp.",nil]];
    [self start:nil];
}


scalarAccessor(id, delegate, setDelegate)

@end
