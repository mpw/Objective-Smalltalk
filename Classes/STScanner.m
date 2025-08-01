/* STScanner.m created by marcel on Tue 04-Jul-2000 */

#import "STScanner.h"


@interface MPWStringLiteral()

@property (nonatomic,assign) BOOL hasSingleQuotes;

@end


#define stisspace(x)   (isspace(x) || (((unsigned int)x)==0xa0))

@implementation MPWStName

objectAccessor(NSString*, realString, setRealString)

-initWithString:(NSString*)newString
{
    self=[super init];
    [self setRealString:newString];
    return self;
}

-(unichar)characterAtIndex:(NSUInteger)index
{
    return [realString characterAtIndex:index];
}

-(NSUInteger)length
{
    return [realString length];
}

-(void)dealloc
{
    [realString release];
    [super dealloc];
}

-(BOOL)isLiteral
{
    return NO;
}

-(BOOL)isComment
{
    return [self hasPrefix:@"//"];
}

-(BOOL)isEqualToString:(NSString *)aString
{
    return [aString isEqualToString:[self realString]];
}

-(NSUInteger)hash
{
    return [[self realString] hash];
}

@end

@implementation MPWStringLiteral

-(BOOL)isLiteral
{
    return YES;
}

@end

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

-(BOOL)isComment
{
    return NO;
}

@end

@implementation NSString(isKeyword)

-(BOOL)isKeyword
{
    return [self hasSuffix:@":"];
}

-(BOOL)isComment
{
    return [self hasPrefix:@"//"];
}


-(BOOL)isBinary
{
    unichar start=[self characterAtIndex:0];
    if ( start == '!' ) {
        if (self.length == 2 ) {
            return NO;
        }
        return YES;
    }
    return start=='@' || start=='+' || start=='-' ||
    start=='*' || start=='/' || start==',' || start=='>' || start=='<' || start=='=' || start > 256;
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

@implementation STScanner

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
    for (i=0;i<128;i++) {
        if ( isalpha(i)  ) {
            charSwitch[i]=(IDIMP0)[self methodForSelector:@selector(scanASCIIName)];
        } else if (isdigit(i) ) {
            charSwitch[i]=(IDIMP0)[self methodForSelector:@selector(scanNumber)];
        } else if (stisspace(i)  ) {
            charSwitch[i]=(IDIMP0)[self methodForSelector:@selector(skipSpace)];
//        } else if (  i=='-' ) {
//          charSwitch[i]=[self methodForSelector:@selector(scanNegativeNumber)];
        } else  {
            charSwitch[i]=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
        }
    }

    for (i=128;i<256;i++) {
        charSwitch[i]=(IDIMP0)[self methodForSelector:@selector(scanUTF8Name)];
    }
//    charSwitch[0xa0]=(IDIMP0)[self methodForSelector:@selector(skipSpace)];
    charSwitch['\'']=(IDIMP0)[self methodForSelector:@selector(scanString)];
    charSwitch['\"']=(IDIMP0)[self methodForSelector:@selector(scanString)];
    charSwitch['<']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch['+']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch['[']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch['!']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch['?']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch['-']=(IDIMP0)[self methodForSelector:@selector(scanSpecial)];
    charSwitch[':']=(IDIMP0)[self methodForSelector:@selector(scanPossibleAssignment)];
    charSwitch['=']=(IDIMP0)[self methodForSelector:@selector(scanPossibleEquals)];
    charSwitch['_']=(IDIMP0)[self methodForSelector:@selector(scanASCIIName)];
    charSwitch[0]=(IDIMP0)[self methodForSelector:@selector(nop)];
//    charSwitch[10]=[self methodForSelector:@selector(skip)];
//    charSwitch[13]=[self methodForSelector:@selector(skip)];
}

-nop { return nil; }

static inline int decodeUTF8FirstByte( int ch, int *numChars)
{
    int retval=0;
    if ( ch <= 0x7f) {
        retval = ch;
        *numChars=0;
    } else if ( (ch & 0xE0) == 0xC0 ) {
        retval = ch & 31;
        *numChars=1;
    } else if ( (ch & 0xF0) == 0xE0 ) {
        retval = ch & 15;
        *numChars=2;
    } else if ( (ch & 0xF8) == 0xF0 ) {
        retval = ch & 7;
        *numChars=3;
    } else if ( (ch & 0xFC) == 0xF8 ) {
        retval = ch & 3;
        *numChars=4;
    } else if ( (ch & 0xFE) == 0xFC ) {
        retval = ch & 1;
        *numChars=5;
    } else {
        
    }
    return retval;
}


-(int)scanUTF8Char
{
    int theChar=0;
    const unsigned char *cur=(const unsigned char *)pos;
    theChar = *cur;
    int numRemainderBytes=0;
    theChar=decodeUTF8FirstByte(theChar, &numRemainderBytes);
    cur++;
    for (int i=0;i<numRemainderBytes;i++) {
        theChar=(theChar<< 6) | ((*cur++) & 0x3f);
    }
    pos=(const char*)cur;
    return theChar;
}

-(NSString*)scanUTF8Name
{
    int theChar=0;
    NSMutableString *result=[NSMutableString string];
    do {
        theChar = [self scanUTF8Char];
        if ( theChar  ) {
            if ( theChar == 0x2018) {
                NSString *restString=[self scanStringBodyWithStartChar:theChar];
                return restString;
            } else if ( theChar == 0xa0 ){
                [self skipSpace];
                return [self nextObject];
            }
            
            [result appendFormat:@"%C",(unsigned short)theChar];
        }
    } while ( NO);
    return [[[MPWStName alloc] initWithString:result] autorelease];
}


-scanASCIIName
{
    const  char *cur=pos;

    if ( isalpha(*cur) || *cur=='_' ) {
        cur++;
        while ( SCANINBOUNDS(cur) && (isalnum(*cur) || (*cur=='_') || (*cur=='-') ||
						(*cur=='.' && SCANINBOUNDS(cur+1) && isalnum(cur[1])))) {
            cur++;
        }
        if ( SCANINBOUNDS(cur) && *cur ==':' ) {
            cur++;
			if ( SCANINBOUNDS( cur ) && (*cur=='=' || *cur==':' ) ) {
				cur--;
			}
        }
    }
//    [[[MPWStName alloc] initWithString:result] autorelease]
    
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

-scanPossibleEquals
{
    const char *cur=pos;
    if ( SCANINBOUNDS(cur+2) && cur[1] == '|' && cur[2] == '=' ) {
        return [self makeText:3];
    } else if ( SCANINBOUNDS(cur+1) && cur[1] == '|'  ) {
        return [self makeText:2];
    } else {
        return [self scanSpecial];
    }
}

-scanComment
{
    const char *cur=pos;
    while ( SCANINBOUNDS(cur) && *cur != '\n' ) {
        cur++;
    }
    return [self makeText:cur-pos];
}

-scanSpecial
{
    const char *cur=pos;
    int len=1;
    if ( SCANINBOUNDS(cur+1) ) {
        if ( *cur=='<'  && cur[1]=='-' ) {
            len++;
        } else if ( *cur=='<'  && cur[1]=='<') {
            len++;
        } else if ( *cur=='-'  && cur[1]=='>') {
            len++;
        } else if ( *cur=='|'  && cur[1]=='=') {
            len++;
        } else if ( *cur=='+'  && cur[1]=='=') {
            len++;
        } else if ( *cur=='|'  && cur[1]=='{') {
            len++;
        } else if ( *cur=='!'  && cur[1]=='!') {
            len++;
        } else if ( *cur=='/' && SCANINBOUNDS(cur+1) && cur[1]=='/' && cur[-1]!=':') {
            return [self scanComment];
        }
    }
    return [self makeText:len];
}

-(NSStringEncoding)stringEncoding
{
    return NSUTF8StringEncoding;
}

-scanString
{
    const  char *cur=pos;
    char startChar = *cur;
    if ( startChar =='\'' || startChar =='"' ) {
        cur++;
        pos=cur;
        return [self scanStringBodyWithStartChar:startChar];
    } else {
        return nil;
    }
}

-scanStringBodyWithStartChar:(int)startChar
{
    const char *cur=pos;
    id string=nil;
    NSMutableArray *partialStrings=nil;
    {
        while ( SCANINBOUNDS(cur) ) {
            if ( startChar > 255 && *cur < 0) {
                const char *old=pos;
                pos=cur;
                /* int endChar = */[self scanUTF8Char];
                const char *afterDelim=pos;
                pos=old;
                string=[self makeString:cur-old];
                pos=afterDelim;
                break;
            }

            if ( *cur==startChar  ) {
                string=[self makeString:cur-pos];
                UPDATEPOSITION(pos+1);
                if ( SCANINBOUNDS(cur+1) && cur[1] == startChar ) {
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
            } else if ( *cur=='\\'  ) {
                string=[self makeString:cur-pos];
                if ( partialStrings == nil ) {
                    partialStrings = [NSMutableArray array];
                }
                [partialStrings addObject:string];
                if ( SCANINBOUNDS(cur+1) && cur[1] == 'n' ) {
                    cur+=3;
                    [partialStrings addObject:@"\n"];
                    UPDATEPOSITION(cur);
                    break;
                }
            } else {
                cur++;
            }
        }
    }
    if ( partialStrings ) {
        string = [partialStrings componentsJoinedByString:@""];
    }
    MPWStringLiteral *s=[[[MPWStringLiteral alloc] initWithString:string] autorelease];
    s.hasSingleQuotes=startChar == '\'';
    return s;
}

-createDouble:(double)aFloat
{
	return [[self floatClass] numberWithDouble:aFloat];
}

-createInt:(long)anInt
{
	return [[self intClass] numberWithLong:anInt];
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
    if ( SCANINBOUNDS(cur+1) && cur[0]=='0' && tolower(cur[1])=='x') {
        cur+=2;
        long value=0;
        while ( SCANINBOUNDS(cur) && isxdigit(*cur)) {
            value*=16;
            int digit = toupper(*cur)-'0';
            if ( digit > 10 ) {
                digit -= ('A' - '9'  - 1);
            }
            value+=digit;
            
            cur++;
        }
        pos=cur;
        return [self createInt:value];
    } if ( SCANINBOUNDS(cur+1) && cur[0]=='0' && tolower(cur[1])=='b') {
        cur+=2;
        long value=0;
        while ( SCANINBOUNDS(cur) && (*cur=='1' || *cur=='0')) {
            value<<=1;
            value+=*cur - '0';
            cur++;
        }
        pos=cur;
        return [self createInt:value];
    } else {
        while ( SCANINBOUNDS(cur) && isdigit(*cur)) {
            cur++;
        }
        if (*cur=='.' && SCANINBOUNDS(cur+1) && isdigit(cur[1])) {
            cur++;
            while ( SCANINBOUNDS(cur) && isdigit(*cur) ) {
                cur++;
            }
        }
    }
    string=[self makeText:cur-pos];
	if ( !noNumbers ) {
		if ( [string rangeOfString:@"."].length==1 ) {
			return [self createDouble:[string doubleValue]];
		} else {
            return [self createInt:[string longValue]];
		}
	} else {
		return string;
	}
}

-(BOOL)atSpace
{
	return SCANINBOUNDS(pos) && stisspace(*pos);
}

-skipSpace
{
    const char *cur=pos;
    while ( SCANINBOUNDS(cur) && stisspace(*cur) ) {
//        NSLog(@"skipSpace: %c %@",*cur,self);
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

@implementation STScanner(testing)

+scannerWithString:(NSString*)s
{
    return [self scannerWithData:(NSData*)s];
}

+(void)testDoubleStringEscape
{
    STScanner *scanner = [self scannerWithString:@"'ab''c'"];
    id string = [scanner nextToken];
    IDEXPECT( string, @"ab'c", @"should have turned double single quotes into single single quote" );
}

+(void)testConstraintEqual
{
    STScanner *scanner = [self scannerWithString:@"a::=b"];
    id a = [scanner nextToken];
    id eq = [scanner nextToken];
    id b = [scanner nextToken];
    IDEXPECT( a, @"a", @"just the a" );
    IDEXPECT( eq, @"::=", @"constraint equal" );
    IDEXPECT( b, @"b", @"just the b" );
}

+(void)testURLWithUnderscores
{
	STScanner *scanner=[self scannerWithString:@"http://farm1.static.flickr.com/9/86383513_f52e2fbf92.jpg"];
	NSMutableArray *tokens=[NSMutableArray array];
	id nextToken;
	while ( nil != (nextToken=[scanner nextToken] )) {
		[tokens addObject:nextToken];
	}
	INTEXPECT( [tokens count], 9 , @"number of tokens");
}

+(void)testLeftArrow
{
	STScanner *scanner=[self scannerWithString:@"<-"];
    IDEXPECT([scanner nextToken], @"<-", @"single left arrow");
    
}

+(void)testSimpleLiteralString
{
	STScanner *scanner=[self scannerWithString:@"'literal string'"];
    IDEXPECT([scanner nextToken], @"literal string", @"literal string");
}

+(void)singleMinusString
{
	STScanner *scanner=[self scannerWithString:@"'-'"];
    IDEXPECT([scanner nextToken], @"-", @"single minus sign");
    
}

+(void)testRightArrow
{
	STScanner *scanner=[self scannerWithString:@"->"];
    IDEXPECT([scanner nextToken],@"->", @"single right arrow");
}

+(void)testScanUTF8Name
{
    unichar pival=960;
    NSString *pi_string=[NSString stringWithCharacters:&pival length:1];
    STScanner *scanner=[self scannerWithString:pi_string];
    NSString *token=[scanner nextToken];
    INTEXPECT([token length], 1, @"length of scanned token pi");

    INTEXPECT([token characterAtIndex:0], pival, @"pi");
    IDEXPECT(token, pi_string, @"the string");
}

+(void)testScanStringWithUnicodeQuotationMark
{
    NSString *s=@"\u2018Hello\u2019";
    STScanner *scanner=[self scannerWithString:s];
    NSString *token=[[scanner nextToken] realString];
//    NSLog(@"real string: %@/%@",[token class],token);

    IDEXPECT(token,@"Hello",@"string with left quote");
    EXPECTNIL([[scanner nextToken] realString],@"should only have one string");
}

+(void)testNewlineEscape
{
    STScanner *scanner=[self scannerWithString:@"'\\n'"];
    NSString *scanned=[scanner nextToken];
    IDEXPECT(scanned,@"\n", @"newline");
    INTEXPECT( scanned.length,1,@"newline is a single char");
    INTEXPECT([scanned characterAtIndex:0],10,@"newline, numeric");
}

+(void)testNonbreakingSpaceSeparatesLikeSpace
{
    NSString *twoTokensSeparatedByNBSP=@"a\u00a0b";
    STScanner *scanner=[self scannerWithString:twoTokensSeparatedByNBSP];
    IDEXPECT([scanner nextToken],@"a", @"a");
    IDEXPECT([scanner nextToken],@"b", @"b");
}

+(void)testCommentToEndOfLine
{
    NSString *commentOnLine=@"a // some text";
    STScanner *scanner=[self scannerWithString:commentOnLine];
    IDEXPECT([scanner nextToken],@"a", @"a");
    IDEXPECT([scanner nextToken],@"// some text", @"the comment");
}

+(void)testNextLineAfterComment
{
    NSString *commentAndNextLine=@"a // some text\nb";
    STScanner *scanner=[self scannerWithString:commentAndNextLine];
    IDEXPECT([scanner nextToken],@"a", @"a");
    IDEXPECT([scanner nextToken],@"// some text", @"commen");
    IDEXPECT([scanner nextToken],@"b", @"b");
}

+(void)testCoutSyntaxIsSingleToken
{
    STScanner *scanner=[self scannerWithString:@"<<"];
    IDEXPECT([scanner nextToken],@"<<", @"single right arrow");
}

+(void)testBangBangIsUnary
{
    EXPECTFALSE( [@"!!" isBinary],@"bang bang is a HOM, so unary");
}

+(void)testQueryIsUnary
{
    EXPECTFALSE( [@"?" isBinary],@"query is unary");
}

+(void)testBangIsBinary
{
    EXPECTTRUE( [@"!" isBinary],@"bang writeObject:, so binary");
}

+(void)testSoleLinefeed
{
    STScanner *scanner=[self scannerWithString:@"'\\n'"];
    IDEXPECT([scanner nextToken],@"\n", @"linefeed");
    EXPECTNIL( [scanner nextToken],@"nothing after");
}

+(void)testLinefeedInLiteral
{
    STScanner *scanner=[self scannerWithString:@"'Hello World\\n'"];
    IDEXPECT([scanner nextToken],@"Hello World\n", @"linefeed after text");
    EXPECTNIL( [scanner nextToken],@"nothing after");
}


+(NSArray*)testSelectors
{
    return @[
        @"testDoubleStringEscape",
        @"testConstraintEqual",
            @"testURLWithUnderscores",
            @"testLeftArrow",
            @"testRightArrow",
            @"testSimpleLiteralString",
            @"singleMinusString",
            @"testScanUTF8Name",
#if !GNUSTEP
            @"testScanStringWithUnicodeQuotationMark",
#endif
            @"testNewlineEscape",
            @"testNonbreakingSpaceSeparatesLikeSpace",
            @"testCommentToEndOfLine",
        @"testNextLineAfterComment",
        @"testCoutSyntaxIsSingleToken",
        @"testBangBangIsUnary",
        @"testQueryIsUnary",
        @"testBangIsBinary",
        @"testSoleLinefeed",
        @"testLinefeedInLiteral",
        ];
}

@end
