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
objectAccessor(MPWStCompiler , syntaxCheckCompiler, setSyntaxCheckCompiler)
objectAccessor(NSString , baseURL, _setBaseURL)

- (id)init
{
//    NSLog(@"environment: %@",[[NSProcessInfo processInfo] environment]);
    self = [super init];
    if (self) {
        [self setInterpreter:[MPWStCompiler compiler]];
        [self setSyntaxCheckCompiler:[MPWStCompiler compiler]];
        [[self interpreter] bindValue:[MPWByteStream Stdout] toVariableNamed:@"stdout"];
        [[self interpreter] bindValue:self toVariableNamed:@"document"];
        NSDictionary *methods = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"viewbuilder" ofType:@"classdict"]];
        if ( methods ) {
            NSLog(@"setting methods: %@",methods);
            [[self interpreter] defineMethodsInExternalDict:[methods objectForKey:@"methodDict"]];
        }
//        NSLog(@"the answer: %d",(int)[self theAnswer]);
    }
    return self;
}

-(NSString*)manualAddress
{
    return [[address stringValue] length] > 2 ? [NSString stringWithFormat:@"http://%@:51000/",[address stringValue]] : nil;
}

-(BOOL)checkMethodBody
{
    NSString *methodBodyText=[self methodBodyString];
    return ( [methodBodyText length]  < 1) ||
     [syntaxCheckCompiler isValidSyntax:methodBodyText];
}


-(void)saveMethodAtPath:(NSString*)path
{
    if ( [self checkMethodBody] ) {
        [super saveMethodAtPath:path];
    } else {
        NSLog(@"--- invalid syntax ---- ");
    }
}

-(NSString*)url
{
    NSString *laddress=[self manualAddress];
    if ( !laddress ) {
        laddress=[self baseURL];
    }
    NSLog(@"base address from manual or automatic: '%@'",laddress);
    return laddress;
}


- (void)upload {
    NSString *urlstring=[self url];
    if ( [urlstring length]>2 ) {
        id baseRef=[[self interpreter] bindingForString:urlstring];
        [[self interpreter] bindValue:baseRef toVariableNamed:@"baseRef"];
        [[self interpreter] evaluateScriptString:@"scheme:base := baseRef asScheme. "];
        NSLog(@"scheme: %@",[[self interpreter] evaluateScriptString:@"scheme:base"]);
        [[self interpreter] evaluateScriptString:@"base:methods := document methodDict asXml. "];
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
    [self setBaseURL:nil];
    for (NSString *urlstring in urls ) {
        NSString *checkURL=[NSString stringWithFormat:@"%@uniqueID",urlstring];
        NSLog(@"base url: '%@' checkURL: '%@'",urlstring,checkURL );
        NSString *targetID=[NSString stringWithContentsOfURL:[NSURL URLWithString:checkURL]];
        NSLog(@"remote server's ID: %@",targetID);
        NSLog(@"my ID: %@",[self uniqueID]);
        if ( [[self uniqueID] isEqualToString:targetID] ) {
            NSLog(@"matched unique ID: '%@' setting URL to: %@",targetID,urlstring);
            [self setBaseURL:urlstring];
            break;
        } else {
            NSLog(@"did not match");
        }
        
    }
}

-(void)updateSyntaxCheckIndicator
{
    [self setSyntaxCheckedOK:[self checkMethodBody]];
}

- (void)textDidChange:(NSNotification *)aNotification
{
    [self updateSyntaxCheckIndicator];
}

-(void)setUIForMethodHeader:(NSString*)header body:(NSString*)body
{
    NSLog(@"setUIForMethodHeader: %@ body:...",header);
    [super setUIForMethodHeader:header body:body];
    [self updateSyntaxCheckIndicator];
}

@end
