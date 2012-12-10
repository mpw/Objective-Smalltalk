//
//  MethodServer.m
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MethodServer.h"
#import "MPWStCompiler.h"
#import "MPWMethodScheme.h"
#import "MPWBinding.h"

@implementation MethodServer

objectAccessor(MPWStCompiler, interpreter, setInterpreter)
objectAccessor(NSString, methodDictName, setMethodDictName)
objectAccessor(NSString, projectDir, setProjectDir)
objectAccessor(NSString, uniqueID, setUniqueID)

- (id)initWithMethodDictName:(NSString*)newName
{
    self = [super init];
    if (self) {
        [self setMethodDictName:newName];
        [self setProjectDir:[[[NSProcessInfo processInfo] environment] objectForKey:@"PROJECT_DIR"]];
        [self setAsDefault];
        [self handleExceptions];
    }
    
    return self;
}

-(id)init
{
    self= [self initWithMethodDictName:@"methods"];
    return self;
}


static id defaultMethodServer=nil;


-(void)setAsDefault
{
    defaultMethodServer=[self retain];
}

-(void)addException:(NSException*)exception
{
    [[self scheme] addException:exception];
}


+(void)addException:exception
{
    NSLog(@"addException");
    [defaultMethodServer addException:exception];
}

static void CatchException(NSException *exception)
{
    NSLog(@"default exception handler caught: %@",exception);
    [defaultMethodServer addException:exception];
}

-(void)handleExceptions
{
    NSLog(@"will handle exceptions");
    NSSetUncaughtExceptionHandler (&CatchException);
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
    [[self async] setupWebServer];

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
    NSData *dictData = [[NSBundle mainBundle] resourceWithName:[self methodDictName] type:@"classdict"];
    NSLog(@"data %p len: %d",dictData,[dictData length]);
    NSDictionary *dict = [self dictionaryFromData:dictData];
    NSString *uid=[dict objectForKey:@"uniqueID"];
    if ( uid ) {
        [self setUniqueID:uid];
        dict=[dict objectForKey:@"methodDict"];
    }
    return  dict;
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
//    NSLog(@"MethodServer get uri: %@",uri);
    if ( [uri hasPrefix:@"/theAnswer"] ) {
        return [[NSString stringWithFormat:@"theAnswer: %d",(int)[self theAnswer]] asData];
    } else if ( [uri hasPrefix:@"/projectDir"] ) {
        return [[self projectDir] asData];
    } else if ( [uri hasPrefix:@"/uniqueID"] ) {
        return [[self uniqueID] asData];
    } else{
//        NSLog(@"-[%@ get:%@ parameters:%@] -> super",[self class],uri,params);
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
//    NSLog(@"put: %@ -> %@",uri,[putData stringValue]);
    NSData *retval =[super put:uri data:putData parameters:params];
    if ( [delegate respondsToSelector:@selector(didDefineMethods:)] ) {
//        [[delegate afterDelay:0.001] didDefineMethods:self];
        [delegate didDefineMethods:self];
    }

    NSLog(@"will send notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"methodsDefined" object:self];
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
    NSLog(@"setupWebServer");
    [super setupWebServer];
    [[self server] setPort:51000];
    [[self server] setBonjourName:[self methodDictName]];
    [[self server] setTypes:[NSArray arrayWithObjects:@"_http._tcp.",@"_methods._tcp.",nil]];
    NSLog(@"did set up port etc, start it");
    NSError *error=nil;
    [self start:&error];
    NSLog(@"did start, error: %@",error);
}

-(void)stop
{
    [[self server] stop];
}

scalarAccessor(id, delegate, setDelegate)

@end
