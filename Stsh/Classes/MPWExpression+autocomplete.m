//
//  MPWExpression+autocomplete.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/13/14.
//
//

#import "MPWExpression+autocomplete.h"
#import "MPWEvaluator.h"
#import "MPWMessageExpression.h"
#import "MPWIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWStatementList.h"
#import "MPWEvaluator.h"


@implementation MPWExpression(completion)


-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell
{
    return NO;
}


@end

@implementation MPWIdentifierExpression(completion)


-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell
{
    MPWEvaluator *evaluator=[shell evaluator];
    MPWBinding* binding=[[[shell evaluator] localVars] objectForKey:[self name]];
    id value=[binding value];
    if ( value ) {
        if ( [s hasSuffix:@" "]) {
            [shell printCompletions:[shell messageNamesForObject:value matchingPrefix:nil]];
        } else {
            [shell insertStringIntoCurrentEditLine:@" "];
            return YES;
        }
    } else {
        if ( [self scheme] && [evaluator schemeForName:[self scheme]]) {
            [shell completeName:[self name] withNames:[[evaluator schemeForName:[self scheme]] completionsForPartialName:[self name] inContext:evaluator]];
        } else {
            
            NSString *n=[self name];
            [shell completeName:n withNames:[shell identifiersMatchingPrefix:n]];
            //                    [self printCompletions:[self variableNamesMatchingPrefix:[expression name]]];
        }
    }
    return YES;
    
}


@end

@implementation MPWMessageExpression(completion)


-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell
{
    id evaluatedReceiver = [[self receiver] evaluateIn:[shell evaluator]];
    if ( [s hasSuffix:@" "] ) {
        id value=[self evaluateIn:[shell evaluator]];
        NSArray *msgNames=[shell messageNamesForObject:value matchingPrefix:nil];
        [shell printCompletions:msgNames];
    } else if ( [evaluatedReceiver respondsToSelector:[self selector]]) {
        [shell insertStringIntoCurrentEditLine:@" "];
        return YES;
    } else {
        NSString *name=[self messageNameForCompletion];
        if ( [name hasSuffix:@":"]) {
            NSRange exprRange=[s rangeOfString:name];
            name=[name stringByAppendingString:[s substringFromIndex:exprRange.location+exprRange.length]];
        }
        NSArray *msgNames=[shell messageNamesForObject:evaluatedReceiver matchingPrefix:name];
        [shell completeName:name withNames:msgNames];
    }
    return YES;
}
@end

@implementation MPWAssignmentExpression(completion)

-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell
{
    return [[self rhs] completeString:s inShell:shell];
}

@end

@implementation MPWStatementList(completion)

-(BOOL)completeString:(NSString*)s inShell:(id <AutocompleteTarget>)shell
{
    return [[[self statements] lastObject] completeString:statements inShell:shell];
}

@end


