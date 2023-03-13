//
//  MPWExpression+autocomplete.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/13/14.
//
//

#import <ObjectiveSmalltalk/STExpression.h>

@class STEvaluator;



@interface STExpression (autocomplete)


-(NSArray*)completionsForString:(NSString*)s withEvaluator:(STEvaluator*)evaluator resultName:(NSString **)resultName;

@end
