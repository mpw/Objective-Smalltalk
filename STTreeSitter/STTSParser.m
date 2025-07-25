//
//  STTSParser.m
//  STTreeSitter
//
//  Created by Marcel Weiher on 25.07.25.
//

#import "STTSParser.h"
#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <tree_sitter/api.h>


extern const TSLanguage *tree_sitter_sample(void);

@implementation STTSParser

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTSParser(testing) 

+(void)testBasicParse
{
    NSLog(@"got here");
    TSParser *parser = ts_parser_new();
    ts_parser_set_language(parser, tree_sitter_sample());
    
    const char *source_code = "x = 123;\ny = 456;";
    TSTree *tree = ts_parser_parse_string(
                                          parser,
                                          NULL,
                                          source_code,
                                          strlen(source_code)
                                          );
    
    TSNode root_node = ts_tree_root_node(tree);
    char *s = ts_node_string(root_node);
    printf("Syntax tree:\n%s\n", s);
    free(s);
    
    ts_tree_delete(tree);
    ts_parser_delete(parser);
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicParse",
			];
}

@end
