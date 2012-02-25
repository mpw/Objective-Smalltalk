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
objectAccessor(NSString, methodDictName, setMethodDictName)
objectAccessor(NSString, projectDir, setProjectDir)


- (id)initWithMethodDictName:(NSString*)newName
{
    self = [super init];
    if (self) {
        [self setMethodDictName:newName];
        [self setProjectDir:[[[NSProcessInfo processInfo] environment] objectForKey:@"PROJECT_DIR"]];
        // Initialization code here.
    }
    
    return self;
}

-(id)init
{
    return [self initWithMethodDictName:@"methods"];
}

-(id)deserializeData:(NSData*)inputData at:(MPWBinding*)aBinding
{
    if ( [[aBinding name] isEqual:@"methods"] ) {
        return [self dictionaryFromData:inputData];
    }
    return [super deserializeData:inputData at:aBinding];
}



-(void)setupWithInterpreter:anInterpreter
{
    [self setInterpreter:anInterpreter];
    [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
    [[self interpreter] bindValue:self toVariableNamed:@"appDelegate"];
//    NSLog(@"PATH: %@",[MPWStCompiler evaluate:@"env:PATH"]);
    [self defineMethodsInExternalDict:[self externalMethodsDict]];
//    NSLog(@"the answer: %d",[self theAnswer]);
    [self setScheme:[[[MPWMethodScheme alloc] initWithInterpreter:[self interpreter]] autorelease]];
    [self setupWebServer];

}


-(void)setup
{
    [self setupWithInterpreter:[[[MPWStCompiler alloc] init] autorelease]];
}

-(NSDictionary*)dictionaryFromData:(NSData*)dictData
{
    return [NSPropertyListSerialization propertyListFromData: dictData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
    
}


-(NSDictionary*)externalMethodsDict
{
    NSData *dictData = [[NSBundle mainBundle] resourceWithName:[self methodDictName] type:@"plist"];
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

-(NSData*)get:(NSString*)uri
{
    return [uri asData];
}

-(NSData*)get:(NSString*)uri parameters:(NSDictionary*)params
{
  NSLog(@"uri: %@",uri);
    if ( [uri hasPrefix:@"/theAnswer"] ) {
        return [[NSString stringWithFormat:@"theAnswer: %d",(int)[self theAnswer]] asData];
    } else if ( [uri hasPrefix:@"/projectDir"] ) {
        return [[self projectDir] asData];
    } else{
        return [super get:uri parameters:params];
    }
}

-(NSData*)post:(NSString*)uri parameters:postData
{
//    NSLog(@"POST to %@",uri);
//    NSLog(@"values: %@",[postData values]);
    postData=[[[postData values] objectForKey:@"eval"] stringValue];
    NSLog(@"values: %@",postData);
    
    [self eval:postData];
    return [@"" asData];
}

-(NSData*)put:(NSString *)uri data:putData parameters:(NSDictionary*)params
{
    NSLog(@"put: %@ -> %@",uri,[putData stringValue]);
    NSData *retval =[super put:uri data:putData parameters:params];
    if ( [delegate respondsToSelector:@selector(didDefineMethods:)] ) {
        [delegate didDefineMethods:self];
    }
    return retval;
}

-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
//    NSLog(@" define methods in MethodServer: %@",dict);
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
