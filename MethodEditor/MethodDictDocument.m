//
//  MethodDict.m
//  MethodEditor
//
//  Created by Marcel Weiher on 9/25/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import "MethodDictDocument.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWStCompiler.h"

@implementation MethodDictDocument

objectAccessor(MPWStCompiler , interpreter, setInterpreter)

- (id)init
{
    NSLog(@"environment: %@",[[NSProcessInfo processInfo] environment]);
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
        NSLog(@"the answer: %d",[self theAnswer]);
    }
    return self;
}


@end
