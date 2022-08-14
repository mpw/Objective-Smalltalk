//
//  MethodServer.m
//  MethodServer
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MethodServer.h"
#import "STCompiler.h"
#import "MPWMethodScheme.h"
#import "MPWBindingLegacy.h"
#import <ObjectiveHTTPD/MPWHTTPServer.h>

@implementation MethodServer

objectAccessor(STCompiler*, interpreter, setInterpreter)
objectAccessor(NSString*, methodDictName, setMethodDictName)
objectAccessor(NSString*, projectDir, setProjectDir)
objectAccessor(NSString*, uniqueID, setUniqueID)

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

-(void)writePortNumber
{
    if ( [self uniqueID] && [[self server] port]> 0) {
        NSString *port=[NSString stringWithFormat:@"%d",[[self server] port]];
        [port writeToFile:[NSString stringWithFormat:@"/tmp/%@",[self uniqueID]] atomically:YES encoding:NSASCIIStringEncoding error:nil];
    }
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
//    if ( [[aBinding name] isEqual:@"methods"] ) {
//        return [self dictionaryFromData:inputData];
//    }
//    return [super deserializeData:inputData at:aBinding];
}

-(void)setupWithInterpreter:anInterpreter
{
    [self setInterpreter:anInterpreter];
    [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
    [[self interpreter] bindValue:self toVariableNamed:@"methodServer"];
//    NSLog(@"PATH: %@",[STCompiler evaluate:@"env:PATH"]);
    [self setMethodDict:[self externalMethodsDict]];
//    NSLog(@"the answer: %d",[self theAnswer]);
    [self setScheme:[[[MPWMethodScheme alloc] initWithInterpreter:[self interpreter]] autorelease]];
    NSLog(@"done setupWithInterpreter");
}

-(void)setupWebServerInBackground
{
    [[self async] setupWebServer];
}

-(void)setupWithoutStarting
{
    [self setupWithInterpreter:[[[STCompiler alloc] init] autorelease]];
}

-(void)setupMethodServer
{
    [self setupWithoutStarting];
    [self setupWebServerInBackground];
}


-(NSDictionary*)dictionaryFromData:(NSData*)dictData
{
    return dictData ? [NSPropertyListSerialization propertyListWithData: dictData options:NSPropertyListImmutable format:nil error:nil] : nil;
    
}


-(NSDictionary*)externalMethodsDict
{
    NSData *dictData = [[NSBundle mainBundle] resourceWithName:[self methodDictName] type:@"classdict"];
    NSString *dictPath = [[NSBundle mainBundle] pathForResource:[self methodDictName] ofType:@"classdict"];
    NSDictionary *dict = [self dictionaryFromData:dictData];
    return  dict;
}

-(void)setMethodDict:(NSDictionary*)dict
{
    NSString *uid=[dict objectForKey:@"uniqueID"];
    if ( uid ) {
        [self setUniqueID:uid];
        dict=[dict objectForKey:@"methodDict"];
    }
    [self defineMethodsInExternalDict:dict];
}


-eval:(NSString*)aString
{
//    NSLog(@"MethodServer eval: %@",aString);
    id result=@"";
    @try {
        result = [[self interpreter] evaluateScriptString:aString];
    } @catch ( id e ) {
//        NSLog(@"evaluating '%@' threw '%@'",aString,e);
        result = [e description];
//        NSLog(@"result = %@",result);
    }
//    NSLog(@"MethodServer result: %@",result);
    
    return [result asData];
}

-(NSData*)get:(NSString*)uri parameters:(NSDictionary*)params
{
    NSLog(@"MethodServer get uri: %@",uri);
    if ( [uri hasPrefix:@"/theAnswer"] ) {
        return [[NSString stringWithFormat:@"theAnswer: %d",(int)[self theAnswer]] asData];
    } else if ( [uri hasPrefix:@"/projectDir"] ) {
        return [[self projectDir] asData];
    } else if ( [uri hasPrefix:@"/uniqueID"] ) {
        return [[self uniqueID] asData];
    } else{
        NSLog(@"-[%@ get:%@ parameters:%@] -> super",[self class],uri,params);
        return [super get:uri parameters:params];
    }
}

-(NSData*)post:(NSString*)uri parameters:postData
{
    NSLog(@"POST to %@",uri);
    NSLog(@"values: %@",[postData values]);
    NSString *evalString=[[[postData values] objectForKey:@"eval"] stringValue];
    NSString *completeString=[[[postData values] objectForKey:@"complete"] stringValue];
    id result=@"";
    if ( [evalString length] >0) {
        result = [self eval:evalString];
    } else if ( [completeString length] > 0) {
        NSLog(@"complete: %@",completeString);
        @try {
        result = [[self interpreter] completionsForString:completeString];
        } @catch ( NSException *e) {
            NSLog(@"exception trying to complete: '%@' -> %@",completeString,e);
        }
    }

    NSLog(@"result of POST: %@",result);
    return [[result stringValue] asData];
}

-(NSData*)put:(NSString *)uri data:putData parameters:(NSDictionary*)params
{
    NSLog(@"put: %@ -> %@",uri,[putData stringValue]);
    NSData *retval =[super put:uri data:putData parameters:params];
    if ( [delegate respondsToSelector:@selector(didDefineMethods:)] ) {
//        [[delegate afterDelay:0.001] didDefineMethods:self];
        [delegate didDefineMethods:self];
    }
    NSLog(@"=== will send methodsDefined notification");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"methodsDefined" object:self];
    return retval;
}

-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
    NSLog(@" define methods in MethodServer: %@",dict);
    if ( dict ) {
        [[self interpreter] defineMethodsInExternalDict:dict];
        NSLog(@"=== will send methodsDefined notification");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"methodsDefined" object:self];
    }
}


-(void)setupWebServer
{
    NSLog(@"MethodServer setupWebServer");
    [super setupWebServer];
    int port = 51000;
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"methodServerPort"]) {
        port=(int)[[NSUserDefaults standardUserDefaults] integerForKey:@"methodServerPort"];
    }
    [[self server] setPort:port];
    [[self server] setThreadPoolSize:4];
#if 1
    
    NSLog(@"Method Server bonjour name: %@",[self methodDictName]);
    [[self server] setBonjourName:[self methodDictName]];
    [[self server] setTypes:[NSArray arrayWithObjects:@"_http._tcp.",@"_methods._tcp.",nil]];
    NSLog(@"did set up port etc, start it");
    NSError *error=nil;
    [self start:&error];
    [self writePortNumber];
    NSLog(@"did start, port: %d error: %@ ",[[self server] port],error);
#endif
}

-(void)stop
{
    [[self server] stop];
}

scalarAccessor(id, delegate, setDelegate)

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: port: %d uniqueID: %@>",[self class],self,[[self server] port],[self uniqueID]];
}

@end

//#import <ObjectiveSmalltalk/MPWScriptedMethod.h>
//@implementation MPWScriptedMethod(wantToDefineSchemesInMethods)
//
//-freshExecutionContextForRealLocalVars
//{
//    //  FIXME!!
//    //  Linking with parent means our local vars aren't local
//    //  (they are inherited from parent), not linking means
//    //  schemes are not inherited (and can't be modified)
//
////    NSLog(@"freshExecutionContextForRealLocalVars");
//    return [[[[self contextClass] alloc] initWithParent:nil] autorelease];
////    return [[[[self contextClass] alloc] initWithParent:[self compiledInExecutionContext]] autorelease];
//}
//
//
//@end
