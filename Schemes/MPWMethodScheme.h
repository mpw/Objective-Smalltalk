//
//  MPWMethodScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 10/21/11.
//  Copyright (c) 2012 metaobject ltd. All rights reserved.
//

#import "MPWScheme.h"

@class MPWStCompiler;

@interface MPWMethodScheme : MPWScheme
{
    MPWStCompiler   *interpreter;
    NSMutableArray  *exceptions;
}

-(void)addException:(NSException*)exception;

@end
