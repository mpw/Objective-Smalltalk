//
//  MPWMethodHeader.m
//  MPWTalk
//
//  Created by Marcel Weiher on 12/05/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import "MPWMethodHeader.h"
#import "MPWStScanner.h"

@implementation MPWMethodHeader

objectAccessor( NSString* , methodName, setMethodName )
objectAccessor( NSString* , returnTypeName, setReturnTypeName )
objectAccessor(NSMutableArray *, parameterNames, setParameterNames )
objectAccessor(NSMutableArray *, parameterTypes, setParameterTypes )
objectAccessor(NSMutableArray *, methodKeyWords, setMethodKeyWords )

-init
{
	self=[super init];
	[self setParameterNames:[NSMutableArray array]];
	[self setParameterTypes:[NSMutableArray array]];
	[self setMethodKeyWords:[NSMutableArray array]];
	[self setReturnTypeName:@"id"];
	return self;
}

-(void)addParameterName:(NSString*)name type:(NSString*)type keyWord:(NSString*)keyWord
{
	[[self methodKeyWords] addObject:keyWord];
	if ( name && type ) {
		[[self parameterNames] addObject:name];
		[[self parameterTypes] addObject:type];
	}
}

-(int)numArguments
{
	return [[self parameterNames] count];
}

-argumentNameAtIndex:(int)anIndex
{
	return [[self parameterNames] objectAtIndex:anIndex];
}
-argumentTypeAtIndex:(int)anIndex
{
	return [[self parameterTypes] objectAtIndex:anIndex];
}

-typeStringForTypeName:aType
{
	if ( [aType isEqual:@"int"] ) {
		return @"i";
	} else	if ( [aType isEqual:@"float"] ) {
		return @"f";
	} else	if ( [aType isEqual:@"void"] ) {
		return @"v";
	} else {
		return @"@";
	}
}

-(const char*)typeSignature
{
	id sig = [self typeString];
	int siglen = [sig length];
	char *signature=malloc( siglen+1 );
	[sig getCString:signature maxLength:siglen];
	signature[siglen]=0;
	return (const char*)signature;
}

-typeString
{
	NSMutableString *str=[NSMutableString stringWithFormat:@"%@@:",[self typeStringForTypeName:[self returnTypeName]]];int i;
	for (i=0;i<[self numArguments];i++ ){
		[str appendString:[self typeStringForTypeName:[self argumentTypeAtIndex:i]]];
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
	if ( next ) {
		id type;
		id keyword = next;
//		[self addToMethodName:next];
		type = [self parseOptionalTypeNameFromScanner:scanner];
		if ( type == nil ) {
			type=@"id";
		}
		next = [scanner nextToken];
		[self addParameterName:next type:type keyWord:keyword];
	}
	return next;
}

-initWithString:(NSString*)aString
{
	id scanner;
	id optionalReturnType;
	[self init];
	scanner = [MPWStScanner scannerWithData:[aString asData]];
	if ( optionalReturnType = [self parseOptionalTypeNameFromScanner:scanner] ) {
		[self setReturnTypeName:optionalReturnType];
	}
	while ( [self parseAKeyWordFromScanner:scanner] );
	[self setMethodName:[[self methodKeyWords] componentsJoinedByString:@""]];
	return self;
}


-(NSString*)headerString
{
	NSMutableString *headerString = [NSMutableString string];
	if ( ![[self returnTypeName] isEqualTo:@"id"] ) {
		[headerString appendFormat:@"<%@>",[self returnTypeName]];
	}
	if ( [parameterNames count] == 0 ) {
		[headerString appendString:[self methodName]];
	} else {
		int i,max=[[self methodKeyWords] count];
		for (i=0;i<max;i++ ) {
			[headerString appendString:[[self methodKeyWords] objectAtIndex:i]];
			if ( i < [[self parameterNames] count] ) {
				id typeName = [[self parameterTypes] objectAtIndex:i];
				id parametername = [[self parameterNames] objectAtIndex:i];
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
	[super encodeWithCoder:aCoder];
	encodeVar( aCoder, headerString );
}

-initWithCoder:aCoder
{
	id headerString=nil;
	self = [super initWithCoder:aCoder];
	id class=[self class];
	decodeVar( aCoder, headerString );
//	NSLog(@"headerString: %@ %@",headerString,[headerString stringValue]);
	[self release];
	return [[class methodHeaderWithString:[headerString stringValue]] retain];
}


-(void)dealloc
{
	[methodName release];
	[returnTypeName release];
	[parameterNames release];
	[parameterTypes release];
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
	IDEXPECT( [header returnTypeName] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 0 , @"numArguments");
}


+(void)testParseUnaryIntReturnTypedMethodHeader
{
	NSString *testMethodHeader = @"<int>count";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"count" ,@"method name" );
	IDEXPECT( [header returnTypeName] , @"int", @"method return type" );
	INTEXPECT( [header numArguments], 0 , @"numArguments");
}

+(void)testUnaryIntReturnTypedTypeString
{
	NSString *testMethodHeader = @"<int>count";
	NSString *typeString=@"i@:";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , @"method type string for int return" );
}

+(void)testParseKeywordMethodHeader
{
	NSString *testMethodHeader = @"add:otherNumber";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"add:" ,@"method name" );
	IDEXPECT( [header returnTypeName] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 1 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"otherNumber" , @"first argument name");
	IDEXPECT( [header argumentTypeAtIndex:0], @"id" , @"first argument name");
}

+(void)testParseLongKeywordMethodHeader
{
	NSString *testMethodHeader = @"add:otherNumber to:firstNumber with:otherParameter";
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header methodName] , @"add:to:with:" ,@"method name" );
	IDEXPECT( [header returnTypeName] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 3 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"otherNumber" , @"first argument name");
	IDEXPECT( [header argumentTypeAtIndex:0], @"id" , @"first argument name");
	IDEXPECT( [header argumentNameAtIndex:1], @"firstNumber" , @"2nd argument name");
	IDEXPECT( [header argumentTypeAtIndex:1], @"id" , @"2nd argument name");
	IDEXPECT( [header argumentNameAtIndex:2], @"otherParameter" , @"third argument name");
	IDEXPECT( [header argumentTypeAtIndex:2], @"id" , @"third argument name");
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
	IDEXPECT( [header returnTypeName] , @"id", @"method return type" );
	INTEXPECT( [header numArguments], 1 , @"numArguments");
	IDEXPECT( [header argumentNameAtIndex:0], @"anInteger" , @"first argument name");
	IDEXPECT( [header argumentTypeAtIndex:0], @"int" , @"first argument name");
}

+(void)testTypedKeywordTypeString
{
	NSString *testMethodHeader = @"addInt:<int>anInteger";
	NSString *typeString=@"@@:i";
	NSString *msgString=[NSString stringWithFormat:@"method typestring for %@",testMethodHeader];
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , msgString);
}

+(void)testTypedKeywordFloatTypeString
{
	NSString *testMethodHeader = @"addFloat:<float>aFloat";
	NSString *typeString=@"@@:f";
	NSString *msgString=[NSString stringWithFormat:@"method typestring for %@",testMethodHeader];
	MPWMethodHeader *header = [self methodHeaderWithString:testMethodHeader];
	IDEXPECT( [header typeString] , typeString , msgString);
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
    return [NSArray arrayWithObjects:
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
        nil];
}

@end
