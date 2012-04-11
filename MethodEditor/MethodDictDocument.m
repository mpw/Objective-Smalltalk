//
//  MethodDict.m
//  MethodEditor
//
//  Created by Marcel Weiher on 9/25/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import "MethodDictDocument.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWStCompiler.h"

@implementation MethodDictDocument

objectAccessor(MPWStCompiler , interpreter, setInterpreter)
objectAccessor(NSString , baseURL, _setBaseURL)

- (id)init
{
//    NSLog(@"environment: %@",[[NSProcessInfo processInfo] environment]);
    self = [super init];
    if (self) {
        [self setInterpreter:[[[MPWStCompiler alloc] init] autorelease]];
        [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
        [[self interpreter] bindValue:self toVariableNamed:@"document"];
        NSDictionary *methods = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"methods" ofType:@"plist"]];
        if ( methods ) {
            NSLog(@"setting methods: %@",methods);
            [[self interpreter] defineMethodsInExternalDict:methods];
        }
        NSLog(@"the answer: %d",(int)[self theAnswer]);
    }
    return self;
}

-(NSString*)manualAddress
{
    return [[address stringValue] length] > 2 ? [NSString stringWithFormat:@"http://%@:51000/",[address stringValue]] : nil;
}

-(void)checkMethodBody
{
    NSString *methodBodyText=[self methodBodyString];
    @try {
        [interpreter compile:methodBodyText];
    }
    @catch (NSException *exception) {
        NSLog(@"compile failed: %@",exception);
    }
    @finally {
    }
}


-(void)saveMethodAtPath:(NSString*)path
{
    [self checkMethodBody];
    [super saveMethodAtPath:path];
}

-(NSString*)url
{
    NSString *address=[self manualAddress];
    if ( !address ) {
        address=[self baseURL];
    }
    NSLog(@"base address from manual or automatic: '%@'",address);
    return address;
}


- (void)upload {
    NSString *urlstring=[self url];
    if ( [urlstring length]>2 ) {
        id baseRef=[[self interpreter] bindingForString:urlstring];
        [[self interpreter] bindValue:baseRef toVariableNamed:@"baseRef"];
        [[self interpreter] evaluateScriptString:@"scheme:base := baseRef asScheme. "];
        NSLog(@"scheme: %@",[[self interpreter] evaluateScriptString:@"scheme:base"]);
        [[self interpreter] evaluateScriptString:@"base:methods := document dict asXml. "];
    } else {
        NSLog(@"not uploading because I didn't get a URL: %@",urlstring);
    }
}

-(void)setBaseURL:(NSString*)urlstring
{
    [self _setBaseURL:urlstring];
    [[address cell] setPlaceholderString:urlstring];
}

-(void)autoresolveFromURLS:(NSArray*)urls
{
    NSLog(@"autoresolveFromURLs: %@",urls);
    NSString *documentPath=[[self fileURL] path];
    [self setBaseURL:nil];
    for (NSString *urlstring in urls ) {
        NSString *checkURL=[NSString stringWithFormat:@"%@projectDir",urlstring];
        NSLog(@"base url: '%@' checkURL: '%@'",urlstring,checkURL );
        NSString *dir=[NSString stringWithContentsOfURL:[NSURL URLWithString:checkURL]];
        NSLog(@"project path: %@",dir);
        if ( [documentPath hasPrefix:dir] ) {
            NSLog(@"project path matches doc path: '%@'",documentPath);
            [self setBaseURL:urlstring];
            break;
        }
    }
}

@end
