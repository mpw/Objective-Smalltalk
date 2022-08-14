//
//  MPWMethodHeader.m
//  Arch-S
//
//  Created by Marcel Weiher on 12/05/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWMethodHeader.h"
#import "MPWStScanner.h"
#import "STVariableDefinition.h"
#import "STTypeDescriptor.h"

@implementation MPWMethodHeader
{
    NSArray *parameterNames;
}
objectAccessor(NSString*, methodName, setMethodName )
objectAccessor(STTypeDescriptor*, returnType, setReturnType )
objectAccessor(NSMutableArray*, parameterVars, setParameterVars )
objectAccessor(NSMutableArray*, methodKeyWords, setMethodKeyWords )
lazyAccessor(NSArray*, parameterNames, setParameterNames, computeParameterNames)

-init
{
	self=[super init];
	[self setParameterVars:[NSMutableArray array]];
	[self setMethodKeyWords:[NSMutableArray array]];
    [self setReturnType:[STTypeDescriptor descritptorForObjcCode:'@']];
	return self;
}

-(SEL)selector
{
    return NSSelectorFromString([self methodName]);
}



-(void)addParameterName:(NSString*)name type:(NSString*)type keyWord:(NSString*)keyWord
{
	[[self methodKeyWords] addObject:keyWord];
	if ( name && type ) {
        STVariableDefinition *vardef=[[STVariableDefinition new] autorelease];
        vardef.name = name;
        vardef.type = [STTypeDescriptor descritptorForSTTypeName:type];
        [[self parameterVars] addObject:vardef];
	}
}

-(int)numArguments
{
	return (int)[[self parameterVars] count];
}

-(NSArray*)computeParameterNames
{
    return (NSArray*)[[[self parameterVars] collect] name];
}

-(STVariableDefinition*)variableDefAtIndex:(int)anIndex
{
    return [[self parameterVars] objectAtIndex:anIndex];
}

-(NSString*)argumentNameAtIndex:(int)anIndex
{
    return [[self variableDefAtIndex:anIndex] name];
}

-(STTypeDescriptor*)argumentTypeAtIndex:(int)anIndex
{
    return [[self variableDefAtIndex:anIndex] type];
}

-(NSString*)argumentTypeNameAtIndex:(int)anIndex
{
    return [[self argumentTypeAtIndex:anIndex] name];
}

-(const char*)typeSignature
{
	id sig = [self typeString];
	int siglen = (int)[sig length]+1;
	char *signature=malloc( siglen+2 );
	[sig getCString:signature maxLength:siglen encoding:NSISOLatin1StringEncoding];
	return (const char*)signature;
}

-typeString
{
	NSMutableString *str=[NSMutableString stringWithFormat:@"%c@:",[[self returnType] objcTypeCode]];
	for (int i=0;i<[self numArguments];i++ ){
        [str appendFormat:@"%c",[[self argumentTypeAtIndex:i] objcTypeCode]];
	}
	return str;
}

-parseOptionalTypeNameFromScanner:scanner
{
	id typeName=nil;
	id next=[scanner nextToken];
	if ( [next isEqual:@"<"] ) {
		typeName = [scanner nextToken];
		IDEXPECT( [scanner nextToken] , @">" , ([NSString stringWithFormat:@"required close of optional type declaration: %@ scanner: %@",typeName,scanner]) );
	} else {
		[scanner pushBack:next];
	}
	return typeName;
}

+methodHeaderWithString:(NSString*)aString
{
	return [[[self alloc] initWithString:aString] autorelease];
}
#if 0
-(void)addToMethodName:newFragment
{
	[methodKeyWords addObject:newFragment];
	id current=[self methodName];
	if ( !current ) {
		current=@"";
	}
	[self setMethodName:[current stringByAppendingString:newFragment]];
}
#endif
-(id)parseAKeyWordFromScanner:scanner
{
	id next = [scanner nextToken];
    if ( next && ![next isEqualToString:@"{"] && ![next isEqualToString:@"."]) {
		id type;
		id keyword = next;
//		[self addToMethodName:next];
		type = [self parseOptionalTypeNameFromScanner:scanner];
		if ( type == nil ) {
			type=@"id";
		}
		next = [scanner nextToken];
        if ( [next isEqualToString:@"{"] || [next isEqualToString:@"."]) {
            [scanner pushBack:next];
            next=nil;
        }
        [self addParameterName:next type:type keyWord:keyword];
    } else {
        [scanner pushBack:next];
        next=nil;
    }
	return next;
}

-initWithScanner:(MPWStScanner*)scanner
{
    id optionalReturnType;
    self = [self init];
    if ( (optionalReturnType = [self parseOptionalTypeNameFromScanner:scanner]) ) {
        [self setReturnType:[STTypeDescriptor descritptorForSTTypeName:optionalReturnType]];
    }
    while ( [self parseAKeyWordFromScanner:scanner] )  {
    }
    [self setMethodName:[[self methodKeyWords] componentsJoinedByString:@""]];
    return self;
}


-initWithString:(NSString*)aString
{
    return [self initWithScanner:[MPWStScanner scannerWithData:[(aString ?: @"") asData]]];
}


-(NSString*)headerString
{
	NSMutableString *headerString = [NSMutableString string];
	if ( [[self returnType] objcTypeCode] != '@' ) {
		[headerString appendFormat:@"<%@>",[[self returnType] name]];
	}
	if ( [parameterVars count] == 0 ) {
		[headerString appendString:[self methodName]];
	} else {
		int i,max=(int)[[self methodKeyWords] count];
		for (i=0;i<max;i++ ) {
			[headerString appendString:[[self methodKeyWords] objectAtIndex:i]];
			if ( i < [[self parameterVars] count] ) {
				id typeName = [[self argumentTypeAtIndex:i] name];
				id parametername = [self argumentNameAtIndex:i];
				if ( [typeName isEqual:@"id"] ) {
					[headerString appendString:parametername];
				} else {
					[headerString appendFormat:@"<%@>%@",typeName,parametername];
				}
				if ( i < max-1 ) {
					[headerString appendString:@" "];
				}
			}
		}
		
	}
	return headerString;
}

-(void)encodeWithCoder:aCoder
{
	id headerString=[[self headerString] dataUsingEncoding:NSUTF8StringEncoding];
	encodeVar( aCoder, headerString );
}

-initWithCoder:aCoder
{
	id headerString=nil;
	id class=[self class];
	decodeVar( aCoder, headerString );
//	NSLog(@"headerString: %@ %@",headerString,[headerString stringValue]);
	[self release];
	return [[class methodHeaderWithString:[headerString stringValue]] retain];
}

-(NSString *)description
{
    return [self headerString];
}

-(void)dealloc
{
	[methodName release];
	[returnType release];
	[parameterVars release];
	[methodKeyWords release];
	[super dealloc];
}

@end

@implementation MPWMethodHeader(testing)


+(void)testParseUnaryUntypedMethodHeader
{
	NSString *testMethodHeader = @"count";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , testMethodHeader ,@"method name" );
	IDEXPECT( [[header returnType] name] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 0 , @"numArguments");
}


+(void)testParseUnaryIntReturnTypedMethodHeader
{
	NSString *testMethodHeader = @"<int>count";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"count" ,@"method name" );
	IDEXPECT( [[header returnType] name] , @"int", @"method return type" );
	INTEXPECT( [header numArguments], 0 , @"numArguments");
}

+(void)testUnaryIntReturnTypedTypeString
{
	NSString *testMethodHeader = @"<int>count";
	NSString *typeString=@"l@:";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , @"method type string for int return" );
}

+(void)testParseKeywordMethodHeader
{
	NSString *testMethodHeader = @"add:otherNumber";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"add:" ,@"method name" );
	IDEXPECT( [[header returnType] name] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 1 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"otherNumber" , @"first argument name");
	IDEXPECT( [header argumentTypeNameAtIndex:0], @"id" , @"first argument name");
}

+(void)testParseLongKeywordMethodHeader
{
	NSString *testMethodHeader = @"add:otherNumber to:firstNumber with:otherParameter";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"add:to:with:" ,@"method name" );
	IDEXPECT( [[header returnType] name] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 3 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"otherNumber" , @"first argument name");
	IDEXPECT( [header argumentTypeNameAtIndex:0], @"id" , @"first argument name");
	IDEXPECT( [header argumentNameAtIndex:1], @"firstNumber" , @"2nd argument name");
	IDEXPECT( [header argumentTypeNameAtIndex:1], @"id" , @"2nd argument name");
	IDEXPECT( [header argumentNameAtIndex:2], @"otherParameter" , @"third argument name");
	IDEXPECT( [header argumentTypeNameAtIndex:2], @"id" , @"third argument name");
}

+(void)testLongKeywordMethodHeaderTypeString
{
	NSString *testMethodHeader = @"add:otherNumber to:firstNumber with:otherParameter";
	NSString *typeString=@"@@:@@@";
	NSString *msgString=[NSString stringWithFormat:@"method typestring for %@",testMethodHeader];
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , msgString);
}


+(void)testParseTypedKeywordMethodHeader
{
	NSString *testMethodHeader = @"addInt:<int>anInteger";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"addInt:" ,@"method name" );
	IDEXPECT( [[header returnType] name] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 1 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"anInteger" , @"first argument name");
	IDEXPECT( [header argumentTypeNameAtIndex:0], @"int" , @"first argument name");
}

+(void)testTypedKeywordTypeString
{
	NSString *testMethodHeader = @"addInt:<int>anInteger";
	NSString *typeString=@"@@:l";
	NSString *msgString=[NSString stringWithFormat:@"method typestring for %@",testMethodHeader];
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , msgString);
}

+(void)testTypedKeywordFloatTypeString
{
	NSString *testMethodHeader = @"addFloat:<float>aFloat";
	NSString *typeString=@"@@:d";
	NSString *msgString=[NSString stringWithFormat:@"method typestring for %@",testMethodHeader];
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , msgString);
}

+(void)testMethodHeaderFollowedByPeriod
{
    NSString *testMethodHeader = @"someMethod. otherMethod.";
    MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
    IDEXPECT([header methodName], @"someMethod",@"shouldn't include the period");
}


+(void)_parseHeaderString:(NSString*)headerString andCompareGeneratedWithCanonical:(NSString*)canonical
{
	MPWMethodHeader *header = [self methodHeaderWithString:headerString];
	NSString *recomputedString = [header headerString];
	IDEXPECT( recomputedString, canonical, @"computed header strings");
}

+(void)_parseHeaderStringAndCompareGeneratedWithOriginal:(NSString*)headerString
{
	[self _parseHeaderString:headerString andCompareGeneratedWithCanonical:headerString];
}

+(void)testReconstitutedParameterString
{
	NSArray *testHeaders=[NSArray arrayWithObjects:
		@"count",
		@"<int>count",
		@"addInt:<int>a",
		@"<float>addInt:<int>a additionalArg:b",
		nil];
	[[self do] _parseHeaderStringAndCompareGeneratedWithOriginal:[testHeaders each]];
}

+(void)testCanonicalParameterString
{
	NSArray *testHeaders=[NSArray arrayWithObjects:
		@"<id>  count",
		nil];
	NSArray *canonicalHeaders=[NSArray arrayWithObjects:
		@"count",
		nil];
	[[self do] _parseHeaderString:[testHeaders each] andCompareGeneratedWithCanonical:[canonicalHeaders each]];
}



+(NSArray*)testSelectors
{
    return @[
		@"testParseUnaryUntypedMethodHeader",
		@"testParseUnaryIntReturnTypedMethodHeader",
		@"testParseKeywordMethodHeader",
		@"testParseLongKeywordMethodHeader",
		@"testLongKeywordMethodHeaderTypeString",
		@"testUnaryIntReturnTypedTypeString",
		@"testParseTypedKeywordMethodHeader",
		@"testTypedKeywordTypeString",
		@"testTypedKeywordFloatTypeString",
		@"testReconstitutedParameterString",
		@"testCanonicalParameterString",
        @"testMethodHeaderFollowedByPeriod",
        ];

}

@end
