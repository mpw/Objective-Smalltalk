//
//  MPWObjCGenerator.m
//  MPWTalk
//
//  Created by Marcel Weiher on 15/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWObjCGenerator.h"


@implementation MPWObjCGenerator

+defaultTarget
{
    return [NSMutableString string];
}

-(SEL)streamWriterMessage
{
    return @selector(generateObjectiveCOn:);
}

-(void)generateVariableWithName:aName
{
    [self writeString:aName];
}

-(void)writeNSString:aString
{
    [self writeString:@"@\""];
    [self writeString:aString];
    [self writeString:@"\""];
}

-(void)writeKeyWord:aKeyWord andArg:arg
{
    [self writeString:@" "];
    [self writeString:aKeyWord];
    [self writeString:@":"];
    [self writeObject:arg];
}

-(void)writeMessage:selector toReceiver:receiver withArgs:args
{
    [self writeString:@"["];
    [self writeObject:receiver];
    if ( [args count] == 0 ) {
        [self writeString:@" "];
        [self writeString:selector];
    } else {
        [[self do] writeKeyWord:[[selector componentsSeparatedByString:@":"] each] andArg:[args each]];
    }
    [self writeString:@"]"];
}

-(void)writeStatements:aList
{
    [self writeEnumerator:[aList objectEnumerator] spacer:@";\n"];
}

@end

@implementation NSObject(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [self writeOnByteStream:aGenerator];
}


@end

@implementation NSString(generateObjectiveCOn)

-(void)generateObjectiveCOn:aGenerator
{
    [aGenerator writeNSString:self];
}

@end