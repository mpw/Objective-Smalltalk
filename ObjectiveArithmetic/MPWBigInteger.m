//
//  MPWBigInteger.m
//  ObjectiveArithmetic
//
//  Created by Marcel Weiher on 14.08.19.
//

#import "MPWBigInteger.h"
#include <gmp.h>

@import MPWFoundation;

@implementation MPWBigInteger
{
@public
    mpz_t n;
}

-(BOOL)isSuper
{
    return NO;
}

-to:other
{
    return [MPWInterval intervalFrom:self to:other];
}

+(instancetype)numberWithString:(NSString*)s
{
    return [[[self alloc] initWithString:s] autorelease];
}

+(instancetype)numberWithLong:(long)l
{
    return [[[self alloc] initWithLong:l] autorelease];
}

-(instancetype)initWithString:(NSString*)s
{
    self=[super init];
    mpz_init(n);
    mpz_set_ui(n,0);

    mpz_set_str(n,[s UTF8String], 10);
    return self;
}

-(instancetype)initWithLong:(long)l
{
    self=[super init];
    mpz_init(n);
    mpz_set_si(n,l);
    return self;
}

-(instancetype)initMPZ:(mpz_t)new_n
{
    self=[super init];
    mpz_set( n, new_n);
    return self;
}

-(mpz_t*)t
{
    return &n;
}

-(long)longValue
{
    return mpz_get_si(n);
}

-(instancetype)add:(MPWBigInteger*)other
{
    mpz_t result;
    mpz_init(result);
    mpz_add( result, n, *[other t]);
    return [[[[self class] alloc] initMPZ:result] autorelease];
}

-(instancetype)sub:(MPWBigInteger*)other
{
    mpz_t result;
    mpz_init(result);
    mpz_sub( result, n, *[other t]);
    return [[[[self class] alloc] initMPZ:result] autorelease];
}

-(instancetype)mul:(MPWBigInteger*)other
{
    mpz_t result;
    mpz_init(result);
    mpz_mul( result, n, *[other t]);
    return [[[[self class] alloc] initMPZ:result] autorelease];
}

-(instancetype)div:(MPWBigInteger*)other
{
    mpz_t result;
    mpz_init(result);
    mpz_div( result, n, *[other t]);
    return [[[[self class] alloc] initMPZ:result] autorelease];
}

-(int)intValue
{
    return (int)mpz_get_si(n);
}


-(NSString*)stringValue
{
    char *s = mpz_get_str (NULL, 10, n);
    NSString *str=[NSString stringWithUTF8String:s];
    free(s);
    return str;

}

-(NSString *)description
{
    return [self stringValue];
}


-(instancetype)factorial
{
    if ( [self intValue] > 2 ) {
        return [self mul:[[self sub:[[self class] numberWithString:@"1"]] factorial]];
    } else {
        return self;
    }
}

@end



@implementation MPWBigInteger(tests)

+(void)testBasicCreationAndAccessing
{
    INTEXPECT([[self numberWithString:@"123"] intValue], 123, @"basic acccessing");
    INTEXPECT([[self numberWithString:@"42"] intValue], 42, @"basic acccessing");
}

+(void)testBasicArithmetic
{
    MPWBigInteger *a=[self numberWithLong:1000];
    MPWBigInteger *b=[self numberWithLong:2];

    INTEXPECT([[a add:b] intValue], 1002, @"add");
    INTEXPECT([[a sub:b] intValue], 998, @"subtract");
    INTEXPECT([[a mul:b] intValue], 2000, @"multiply");
    INTEXPECT([[a div:b] intValue], 500, @"divide");


}

+(void)testToString
{
    IDEXPECT( [[self numberWithString:@"123"] stringValue], @"123",@"bignum to string");
}

+(void)testFactorial
{
    INTEXPECT( [[[self numberWithLong:3] factorial] longValue], 6, @"3 factorial");
    INTEXPECT( [[[self numberWithLong:4] factorial] longValue], 24, @"4 factorial");
    IDEXPECT( [[[self numberWithLong:100] factorial] stringValue], @"93326215443944152681699238856266700490715968264381621468592963895217599993229915608941463976156518286253697920827223758251185210916864000000000000000000000000", @"100 factorial");
}

+testSelectors
{
    return @[
             @"testBasicCreationAndAccessing",
             @"testBasicArithmetic",
             @"testToString",
             @"testFactorial",
             ];
}

@end

