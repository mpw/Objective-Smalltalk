//
//  MPWGenericBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 11/27/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWGenericBinding.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWGenericScheme.h"
#import "MPWIdentifier.h"

@implementation MPWGenericBinding


-initWithName:(NSString*)envName scheme:newScheme
{
	self=[super init];
    MPWIdentifier *identifier=[MPWIdentifier referenceWithPath:envName];
    self.reference=identifier;
    self.store=newScheme;
	return self;
}

+bindingWithName:(NSString*)envName scheme:newScheme
{
    return [[[self alloc] initWithName:envName scheme:newScheme] autorelease];
}


#define GENERICSCHEME  ((MPWGenericScheme*)self.store)

-(BOOL)isBound
{
	return [GENERICSCHEME isBoundBinding:self];
}

//-(BOOL)hasChildren
//{
//    return [GENERICSCHEME hasChildren:self];
//}

@end
