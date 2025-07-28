//
//  STTSNode.m
//  STTreeSitter
//
//  Created by Marcel Weiher on 28.07.25.
//

#import "STTSNode.h"
#include <tree_sitter/api.h>

@implementation STTSNode
{
    TSNode *node;
}

-initWithNode:(void*)aNode
{
    if ( self=[super init]) {
        node=(TSNode*)aNode;
    }
    return self;
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTSNode(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
