/* MPWStScanner.m created by marcel on Tue 04-Jul-2000 */

#import "MPWStScanner.h"

@implementation NSObject(isLiteral)


-(BOOL)isLiteral
{
    return YES;
}

-(BOOL)isToken
{
    return ![self isLiteral];
}

-(BOOL)isKeyword
{
    return NO;
}

-(BOOL)isBinary
{
    return NO;
}

@end

@implementation NSString(isKeyword)

-(BOOL)isKeyword
{
    return [self hasSuffix:@":"];
}

-(BOOL)isBinary
{
    unichar start=[self characterAtIndex:0];
    return start=='@' || start=='+' || start=='-' ||
        start=='*' || start=='/' || start==',' || start=='>' || start=='<' || start=='=';
}

-(BOOL)isScheme
{
	return [self isKeyword];
}

@end

@implementation MPWSubData(isLiteral)

-(BOOL)isLiteral
{
    return NO;
}

@end

@implementation MPWStScanner

scalarAccessor( Class, intClass, setIntClass )
scalarAccessor( Class, floatClass, setFloatClass )
scalarAccessor( Class, stringClass, setStringClass )
idAccessor( tokens, setTokens )
boolAccessor( noNumbers, setNoNumbers )

-(Class)defaultIntClass
{
	return [NSNumber class];
}

-(Class)defaultFloatClass
{
	return [NSNumber class];
}

-(Class)defaultStringClass
{
	return [NSString class];
}

-initWithDataSource:aDataSource
{
	self = [super initWithDataSource:aDataSource];
	[self setIntClass:[self defaultIntClass]];
	[self setFloatClass:[self defaultFloatClass]];
	[self setStringClass:[self defaultStringClass]];
	[self setTokens:[NSMutableArray array]];
	return self;
}


-(void)_initCharSwitch
{
    unsigned int i;

    [super _initCharSwitch];
    for (i=0;i<256;i++) {
        if ( isalpha(i) ) {
            charSwitch[i]=[self methodForSelector:@selector(scanName)];
        } else if (isdigit(i) ) {
            charSwitch[i]=[self methodForSelector:@selector(scanNumber)];
        } else if (isspace(i)  ) {
            charSwitch[i]=[self methodForSelector:@selector(skipSpace)];
//        } else if (  i=='-' ) {
//          charSwitch[i]=[self methodForSelector:@selector(scanNegativeNumber)];
        } else {
            charSwitch[i]=[self methodForSelector:@selector(scanSpecial)];
        }
    }
    charSwitch['\'']=[self methodForSelector:@selector(scanString)];
    charSwitch['\"']=[self methodForSelector:@selector(scanComment)];
    charSwitch['<']=[self methodForSelector:@selector(scanSpecial)];
    charSwitch['+']=[self methodForSelector:@selector(scanSpecial)];
    charSwitch['[']=[self methodForSelector:@selector(scanSpecial)];
    charSwitch[':']=[self methodForSelector:@selector(scanPossibleAssignment)];
    charSwitch['_']=[self methodForSelector:@selector(scanName)];
    charSwitch[0]=[self methodForSelector:@selector(skip)];
//    charSwitch[10]=[self methodForSelector:@selector(skip)];
//    charSwitch[13]=[self methodForSelector:@selector(skip)];
}



-scanName
{
    const  char *cur=pos;

    if ( isalpha(*cur) || *cur=='_') {
        cur++;
        while ( SCANINBOUNDS(cur) && (isalnum(*cur) || (*cur=='_') || (*cur=='-') ||
						(*cur=='.' && SCANINBOUNDS(cur+1) && isalnum(cur[1])))) {
            cur++;
        }
        if ( SCANINBOUNDS(cur) && *cur==':' ) {
            cur++;
			if ( SCANINBOUNDS( cur ) && (*cur=='=' || *cur==':' ) ) {
				cur--;
			}
        }
    }
    return [self makeText:cur-pos];     
}

-scanPossibleAssignment
{
    const char *cur=pos;
	cur++;
	if ( SCANINBOUNDS( cur ) &&  (*cur==':') ) {
		cur++;
	}
	if ( SCANINBOUNDS( cur ) &&  (*cur=='=') ) {
		cur++;
	}
    return [self makeText:cur-pos];     
}

-scanSpecial
{
    const char *cur=pos;
    int len=1;
    if ( *cur=='<' && SCANINBOUNDS(cur+1) && cur[1]=='-' ) {
        len++;
    }
    return [self makeText:len];
}

-scanString
{
    NSMutableArray *partialStrings=nil;
    const  char *cur=pos;
    id string=nil;
    if ( *cur =='\'' ) {
        cur++;
        pos=cur;
        while ( SCANINBOUNDS(cur) ) {
            if ( *cur=='\''  ) {
                string=[self makeString:cur-pos];
                UPDATEPOSITION(pos+1);
                if ( SCANINBOUNDS(cur+1) && cur[1] == '\'' ) {
                    if ( partialStrings == nil ) {
                        partialStrings = [NSMutableArray array];
                    }
                    [partialStrings addObject:string];
                    cur+=2;
                } else {
                    if ( partialStrings ) {
                        [partialStrings addObject:string];
                    }
                    break;
                }
            } else {
                cur++;
            }
        }
    }
    if ( partialStrings ) {
        return [partialStrings componentsJoinedByString:@""];
    } else {
        return string;
    }
}

-createFloat:(float)aFloat
{
	return [[self floatClass] numberWithFloat:aFloat];
}

-createInt:(int)anInt
{
	return [[self intClass] numberWithInt:anInt];
}

-createString:(NSString*)aString
{
	return [[self stringClass] stringWithString:aString];
}


-scanNumber
{
    const char *cur=pos;
    id string;
//	int numPeriods=0;
    while ( SCANINBOUNDS(cur) && isdigit(*cur)) {
        cur++;
    }
	if (*cur=='.' && SCANINBOUNDS(cur+1) && isdigit(cur[1])) {
		cur++;
		while ( SCANINBOUNDS(cur) && isdigit(*cur) ) {
			cur++;
		}
	}
    string=[self makeText:cur-pos];
	if ( !noNumbers ) {
		if ( [string rangeOfString:@"."].length==1 ) {
			return [self createFloat:[string floatValue]];
		} else {
			return [self createInt:[string intValue]];
		}
	} else {
		return string;
	}
}

-(BOOL)atSpace
{
	return SCANINBOUNDS(pos) && isspace(*pos);
}

-skipSpace
{
    const char *cur=pos;
    while ( SCANINBOUNDS(cur) && isspace(*cur) ) {
        cur++;
    }
    UPDATEPOSITION(cur);
    return nil;
}

-nextObject
{
    id n;
    [self skipSpace];
    n = [super nextObject];
    return n;
}

-nextToken
{
    id result;
    if ( [tokens count] ) {
        result=[tokens lastObject];
        [tokens removeLastObject];
    } else {
        result=[self nextObject];
    }
    return result;
}

-(void)pushBack:aToken
{
    if ( aToken ) {
        [tokens addObject:aToken];
    }
}
@end

@implementation MPWStScanner(testing)

+(void)testDoubleStringEscape
{
    MPWStScanner *scanner = [self scannerWithData:@"'ab''c'"];
    id string = [scanner nextToken];
    IDEXPECT( string, @"ab'c", @"should have turned double single quotes into single single quote" );
}

+(void)testConstraintEqual
{
    MPWStScanner *scanner = [self scannerWithData:@"a::=b"];
    id a = [scanner nextToken];
    id eq = [scanner nextToken];
    id b = [scanner nextToken];
    IDEXPECT( a, @"a", @"just the a" );
    IDEXPECT( eq, @"::=", @"constraint equal" );
    IDEXPECT( b, @"b", @"just the b" );
}

+(void)testURLWithUnderscores
{
	MPWStScanner *scanner=[self scannerWithData:@"http://farm1.static.flickr.com/9/86383513_f52e2fbf92.jpg"];
	NSMutableArray *tokens=[NSMutableArray array];
	id nextToken;
	while ( nil != (nextToken=[scanner nextToken] )) {
		[tokens addObject:nextToken];
	}
	INTEXPECT( [tokens count], 9 , @"number of tokens");
}

+(void)testLeftArrow
{
	MPWStScanner *scanner=[self scannerWithData:@"<-"];
    IDEXPECT([scanner nextToken], @"<-", @"single left arrow");

}

+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:
        @"testDoubleStringEscape",
        @"testConstraintEqual",
            @"testURLWithUnderscores",
            @"testLeftArrow",
        nil];
}

@end
