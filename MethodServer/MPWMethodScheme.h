//
//  MPWMethodScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 10/21/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWGenericScheme.h"

@class MPWStCompiler;

@interface MPWMethodScheme : MPWGenericScheme
{
    MPWStCompiler   *interpreter;
    NSMutableArray  *exceptions;
}

@end
