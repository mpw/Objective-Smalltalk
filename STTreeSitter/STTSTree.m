//
//  STTSTree.m
//  STTreeSitter
//
//  Created by Marcel Weiher on 28.07.25.
//

#import "STTSTree.h"
#include <tree_sitter/api.h>

@implementation STTSTree
{
    TSTree *tree;
}

-(instancetype)initWithTree:(void*)aTree
{
    if (self=[super init]) {
        tree=aTree;
    }
    return self;
}

-(NSString *)description
{
    TSNode root=ts_tree_root_node(tree);
    char *s=ts_node_string(root);
    NSString *description=@(s);
    free(s);
    return description;
}

-(void)dealloc
{
    if (tree) {
        ts_tree_delete(tree);
    }
    [super dealloc];
}



@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTSTree(testing) 

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
