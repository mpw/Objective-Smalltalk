//
//  MPWExpression+autocomplete.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/13/14.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@class MPWEvaluator;



@interface MPWExpression (autocomplete)


-(NSArray*)completionsForString:(NSString*)s withEvaluator:(MPWEvaluator*)evaluator resultName:(NSString **)resultName;

@end
