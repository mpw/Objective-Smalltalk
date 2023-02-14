//
//  MPWExpression+autocomplete.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/13/14.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class STEvaluator;



@interface MPWExpression (autocomplete)


-(NSArray*)completionsForString:(NSString*)s withEvaluator:(STEvaluator*)evaluator resultName:(NSString **)resultName;

@end
