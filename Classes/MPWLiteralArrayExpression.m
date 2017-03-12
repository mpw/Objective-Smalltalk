//
//  MPWLiteralArrayExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralArrayExpression.h"

@implementation MPWLiteralArrayExpression

-evaluateIn:aContext
{
//    NSLog(@"will evaluate literarl array: %@",[self objects]);
#define STACKMAX 200
    
    long max=self.objects.count;
    id stackEvalResults[ STACKMAX ];
    id *evalResults=stackEvalResults;
    id *heapEvalResults=nil;
    if ( max < STACKMAX ) {
        evalResults=stackEvalResults;
    } else {
        heapEvalResults=calloc( max, sizeof(id));
        evalResults=heapEvalResults;
    }
    
    for ( int i=0;i<max;i++) {
        evalResults[i]=[self.objects[i] evaluateIn:aContext];
    }
//    NSLog(@"evaluated literal array :%@",result);
    NSArray *result= [NSArray arrayWithObjects:evalResults count:max];
    free(heapEvalResults);
    return result;
}

-(void)dealloc
{
    [_objects release];
    [super dealloc];
}

@end
