//
//  MPWLiteralArrayExpression.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/22/17.
//
//

#import "MPWLiteralArrayExpression.h"

@interface MPWLiteralArrayExpression()


@end

@implementation MPWLiteralArrayExpression

-(void)setClassName:(NSString *)name
{
//    [super setClassName:name];
    if ( name ) {
        self.literalClassName=name;
    }
}

-(NSArray*)evaluated
{
    
}

-evaluateIn:aContext
{
//    NSLog(@"will evaluate literal array: %@",[self objects]);
#define STACKMAX 200
    Class baseClass=[NSArray class];
    Class finalClass=[self classForContext:aContext];
    long max=self.objects.count;
    id stackEvalResults[ STACKMAX ];
    id *evalResults=stackEvalResults;
    id *heapEvalResults=NULL;
    if ( max < STACKMAX ) {
        evalResults=stackEvalResults;
    } else {
        heapEvalResults=calloc( max, sizeof(id));
        evalResults=heapEvalResults;
    }
    if ( self.literalClassName && !finalClass ) {
        [NSException raise:@"classnotfound" format:@"Class '%@ not found in literal array expression",self.literalClassName];
    }

    for ( int i=0;i<max;i++) {
        evalResults[i]=[self.objects[i] evaluateIn:aContext];
    }
    if ( [finalClass respondsToSelector:@selector(arrayWithObjects:count:)] ) {
        baseClass=finalClass;
    }
    NSArray *result= [baseClass arrayWithObjects:evalResults count:max];
    if ( finalClass && finalClass != baseClass && [finalClass instancesRespondToSelector:@selector(initWithArray:)] ) {
        result=[[[finalClass alloc] initWithArray:result] autorelease];
    }
    free(heapEvalResults);
    return result;
}

-(void)dealloc
{
    [_objects release];
    [super dealloc];
}

@end


