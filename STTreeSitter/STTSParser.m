//
//  STTSParser.m
//  STTreeSitter
//
//  Created by Marcel Weiher on 25.07.25.
//

#import "STTSParser.h"
#import "STTSTree.h"

#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <tree_sitter/api.h>


extern const TSLanguage *tree_sitter_objectives(void);

@implementation STTSParser
{
    TSParser *parser;
}

-init
{
    self=[super init];
    if (self) {
        parser = ts_parser_new();
        ts_parser_set_language(parser, tree_sitter_objectives());
    } else {
        return nil;
    }
    return self;
}

-(STTSTree*)parse:(NSString*)source
{
    char *source_code=[source UTF8String];
    
    TSTree *tree = ts_parser_parse_string(
                                          parser,
                                          NULL,
                                          source_code,
                                          (int)strlen(source_code)
                                          );
    return [[[STTSTree alloc] initWithTree:tree] autorelease];
}

-(void)dealloc
{
    if (parser) {
        ts_parser_delete(parser);
    }
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STTSParser(testing) 

+(void)testBasicParse
{
    STTSParser *parser=[self new];
    
    NSString* source_code = @"x = 123;\ny = 456;";
    STTSTree* parsed=[parser parse:source_code];
    
    NSString *treeDescription = [parsed description];
    IDEXPECT(treeDescription,@"(source_file (statement (identifier1) (number)) (statement (identifier1) (number)))",@"parsed tree");
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicParse",
			];
}

@end
