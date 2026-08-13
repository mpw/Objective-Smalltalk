//
//  MPWObjCGenerator.m
//  Arch-S
//
//  Created by Marcel Weiher on 15/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//
//  The Objective-C backend is the identity specialization of the shared
//  Objective-C-family source generator (MPWLanguageGenerator): it keeps NS* class
//  names (the base's mapClassName: is identity) and supplies the #import directive.
//  All emission lives in the base; Objective-J is the sibling that remaps NS→CP.
//

#import "MPWObjCGenerator.h"

@implementation MPWObjCGenerator

+(NSString*)standardImports
{
    return @"#import <Foundation/Foundation.h>\n"
            "#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>\n\n";
}

@end
