//
//  MPWExpression+autocomplete.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/13/14.
//
//

#import "MPWExpression.h"

@class MPWEvaluator;

@protocol AutocompleteTarget <NSObject>



-(NSArray *)messageNamesForObject:value matchingPrefix:(NSString*)prefix;
-(void)printCompletions:(NSArray *)names;
-(void)completeName:(NSString*)currentName withNames:(NSArray*)names;
-(NSArray *)identifiersMatchingPrefix:(NSString*)prefix;
-(void)insertStringIntoCurrentEditLine:(NSString*)stringToInsert;

-(MPWEvaluator*)evaluator;

@end


@interface MPWExpression (autocomplete)


-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell;

@end
