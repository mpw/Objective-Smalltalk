#import <Foundation/Foundation.h>
#import <ObjectiveArithmetic/MPWBigInteger.h>

@interface NSNumber(arith)

-add:other;

@end

@implementation NSNumber(arith)

-add:other
{
    long a=[self longValue];
    long b=[other longValue];
    long result;
    int overflow=__builtin_add_overflow(a, b, &result);
    if ( overflow ) {
        MPWBigInteger *biga=[MPWBigInteger numberWithLong:a];
        MPWBigInteger *bigb=[MPWBigInteger numberWithLong:b];
        return [biga add:bigb];
    }
    //    NSLog(@"a=%d b=%d result=%d",a,b,result);
    return @(result);
}

-mul:other
{
    long a=[self longValue];
    long b=[other longValue];
    long result;
    int overflow=__builtin_mul_overflow(a, b, &result);
    if ( overflow ) {
        MPWBigInteger *biga=[MPWBigInteger numberWithLong:a];
        MPWBigInteger *bigb=[MPWBigInteger numberWithLong:b];
        return [biga mul:bigb];
    }
    //    NSLog(@"a=%d b=%d result=%d",a,b,result);
    return @(result);
}

@end


int main(int argc, char *argv[] ) {
	NSNumber *a=@(9000);
	NSNumber *b=@(9000000000000000000);
    id result=[a mul:b];
    NSLog(@"%@*%@=%@ class:%@",a,b,result,[result class]);
	return 0;
}
