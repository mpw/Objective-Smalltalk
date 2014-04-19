/* MPWStCompiler.m created by marcel on Mon 03-Jul-2000 */

#import "MPWStCompiler.h"
#import "MPWStScanner.h"
#import "MPWMessageExpression.h"
#import "MPWIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWComplexAssignment.h"
#import "MPWStatementList.h"
#import "MPWBlockExpression.h"
#import "MPWInterval.h"
#import "MPWMethodStore.h"
#import "MPWIdentifier.h"
#import "MPWNamedIdentifier.h"
#import "MPWRecursiveIdentifier.h"
#import "MPWURLSchemeResolver.h"
#import "MPWFileSchemeResolver.h"
#import "MPWEnvScheme.h"
#import "MPWBundleScheme.h"
//#import "MPWScriptingBridgeScheme.h"
#import "MPWDefaultsScheme.h"
#import "MPWSchemeScheme.h"
#import "MPWConnectToDefault.h"
#import <MPWFoundation/NSNil.h>

@implementation NSString(concat)

-concat:other
{
	return [self stringByAppendingString:other];
}

@end

@implementation NSMutableArray(concat)

-concat:other
{
	 [self addObject:other];
	 return self;
}


@end


@implementation MPWStCompiler

objectAccessor( MPWStScanner, scanner, setScanner )
objectAccessor( MPWMethodStore, methodStore, setMethodStore )
idAccessor( connectorMap, setConnectorMap );

-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol
{
	[[self connectorMap] setObject:aClass forKey:symbol];
}

-(void)defineBuiltInConnectors
{
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@":="];
	[self defineConnectorClass:[MPWComplexAssignment class] forConnectorSymbol:@"<-"];
	[self defineConnectorClass:[MPWConnectToDefault class] forConnectorSymbol:@"->"];
}

-initWithParent:newParent
{
	self=[super initWithParent:newParent];
	[self setMethodStore:[[[MPWMethodStore alloc] initWithCompiler:self] autorelease]];
	[self setConnectorMap:[NSMutableDictionary dictionary]];
	[self defineBuiltInConnectors];
	return self;
}


//----- compatibilty methods for stuff that's moved to MPWMethodStore

-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString
{
	[[self methodStore] addScript:scriptString forClass:className methodHeaderString:methodHeaderString];
}

-(NSArray*)classesWithScripts
{
	return [[self methodStore] classesWithScripts];
}

-(NSArray*)methodNamesForClassName:(NSString*)aClassName
{
	return [[self methodStore] methodNamesForClassName:aClassName];
}

-(NSDictionary*)externalScriptDict
{
	return [[self methodStore] externalScriptDict];
}

-(void)defineMethodsInExternalDict:(NSDictionary*)aDict
{
	[[self methodStore] defineMethodsInExternalDict:aDict];
}



-methodDictionaryForClassNamed:(NSString*)aName
{
	return [[self methodStore] methodDictionaryForClassNamed:aName];
}

-methodForClass:aClassName name:aMethodName
{
	return [[self methodStore] methodForClass:aClassName name:aMethodName];
}


-createSchemes
{
	id schemes=[super createSchemes];
	id  httpResolver=[MPWURLSchemeResolver scheme];
	[schemes setSchemeHandler:[MPWDefaultsScheme scheme]  forSchemeName:@"defaults"];
	[schemes setSchemeHandler:[MPWFileSchemeResolver scheme]  forSchemeName:@"file"];
	[schemes setSchemeHandler:httpResolver  forSchemeName:@"http"];
	[schemes setSchemeHandler:httpResolver  forSchemeName:@"https"];
	[schemes setSchemeHandler:httpResolver  forSchemeName:@"ftp"];
    
	[schemes setSchemeHandler:[NSClassFromString(@"MPWEnvScheme") scheme]  forSchemeName:@"env"];
	[schemes setSchemeHandler:[MPWBundleScheme scheme]  forSchemeName:@"bundle"];
	[schemes setSchemeHandler:[MPWBundleScheme mainBundleScheme]  forSchemeName:@"mainbundle"];
//	[schemes setSchemeHandler:[MPWScriptingBridgeScheme scheme]  forSchemeName:@"app"];
	
	return schemes;
}




//--- true compiler methods

-nextToken
{
    id token=[scanner nextToken];
    return token;
}

-(void)pushBack:aToken
{
	[scanner pushBack:aToken];
}

+compiler
{
    return [[self new] autorelease];
}

+evaluate:aString
{
    return [[self compiler] evaluateScriptString:aString];
}

-evaluateScriptString:script 
{
    if ( [script isKindOfClass:[NSString class]]) {
        script  = [script compileIn:self];
    
    }
//    NSLog(@"script from '%@'/%@ ->  '%@'",aString,[aString class],script);
	return [super evaluate:script];
}

-lookupScriptNamed:methodName forClassName:className
{
	return [[self methodDictionaryForClassNamed:className] objectForKey:methodName];
}

-evaluateScriptNamed:methodName onObject:receiver
{
	NSString *className=NSStringFromClass([receiver class]);
	NSString *scriptString=[self lookupScriptNamed:methodName forClassName:className];
	return [self evaluateScript:scriptString onObject:receiver];
}

-(void)parseError:(NSString*)msg token:(id)token selector:(SEL)sel
{
    id e=[NSException exceptionWithName:msg reason:[NSString stringWithFormat:@"%@ in '%@' %@/%@ from %@",msg,NSStringFromSelector(sel),token,[token class],scanner] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:scanner,@"scanner",token,@"token",nil]];
    @throw e;
    
}

#define PARSEERROR( msg, theToken )  [self parseError:msg token:theToken selector:_cmd]

-parseObject
{
    id object=[self nextToken];
    if ( ![object isLiteral] ) {
        PARSEERROR(@"invalidobject",object);
    }
    return object;
}

-parseLiteralArray
{
    NSMutableArray *array=[NSMutableArray array];
    id object;
    do {
        object=[self nextToken];
//        NSLog(@"got object: %@",object);
        if ( object && !([object isToken] && [object isEqual:@")"]) ) {
            if ( [object isEqual:@"#"]) {
                object=[self parseLiteral];
            }
            [array addObject:[(MPWExpression*)object evaluate]];
        } else {
            break;
        }
    } while ( YES );
    if ( [object isEqual:@")"] ) {
//        NSLog(@"OK Array found: %@",array);
        return array;
    } else {
        PARSEERROR(@"array syntax", object);
        return nil;
    }
}

-parseLiteral
{
    id object = [self nextToken];
    if ( [object isEqual:@"("] ) {
        return [self parseLiteralArray];
    } else {
        return object;
    }
}

-makeComplexIdentifier:aToken
{
	MPWIdentifierExpression* variable=[[[MPWIdentifierExpression alloc] init] autorelease];
	MPWIdentifier *identifier=[[[MPWNamedIdentifier alloc] init] autorelease];
	MPWIdentifier *identifierToAddNameTo=identifier;
	NSString *scheme=[aToken stringValue];
    [variable setOffset:[scanner offset]];
    [variable setLen:1];
	scheme=[scheme substringToIndex:[scheme length]-1];
	NSString* name;
	id nextToken=nil;
	if ( YES ) {
		//--- have a scheme
		[identifier setSchemeName:scheme];
		if ( [scheme isEqual:@"ref"] ) {
			MPWIdentifier *nextIdentifier=identifier;
            MPWRecursiveIdentifier *thisIdentifier=[[[MPWRecursiveIdentifier alloc] init] autorelease];
            identifier=thisIdentifier;
			[thisIdentifier setSchemeName:scheme];
			[thisIdentifier setNextIdentifier:nextIdentifier];
			[nextIdentifier setSchemeName:nil];
			identifierToAddNameTo=nextIdentifier;
//			NSLog(@"ref scheme");
			NSString *subsequentScheme;
			nextToken=[self nextToken];
			subsequentScheme=[nextToken stringValue];
//			NSLog(@"nextToken: %@",nextToken);
			if ( [subsequentScheme isScheme] ) {
//				NSLog(@"ref token with suffix and new schme: %@",subsequentScheme);
				[nextIdentifier setSchemeName:[subsequentScheme substringToIndex:[subsequentScheme length]-1]];
			} else {
				//				NSLog(@"ref token without new schmeme");
				[self pushBack:nextToken];
			}
		}
		//--- re-initialize name
		name=[NSMutableString string];
		[scanner setNoNumbers:YES];
        id lastToken=nil;
		do {
            lastToken=nextToken;
			nextToken=[self nextToken];
			if (nextToken && ![nextToken isEqual:@")"] ) {
				name=[name stringByAppendingString:[nextToken stringValue]];
			}
		} while (nextToken && ![scanner atSpace] &&  ![nextToken isEqual:@")"] );
        if ( nextToken ) {
            lastToken=nextToken;
        }
        if (   [lastToken isEqual:@"."] ) {
            [self pushBack:lastToken];
            name=[name substringToIndex:[name length]-1];
        } else if ( [lastToken isEqual:@")"]) {
            [self pushBack:lastToken];
        }
		[scanner setNoNumbers:NO];
	}
	[identifierToAddNameTo setIdentifierName:name];
	[identifier setScheme:[self schemeForName:[identifier schemeName]]];
	[identifierToAddNameTo setScheme:[self schemeForName:[identifierToAddNameTo schemeName]]];
	[variable setIdentifier:identifier];
	[variable setEvaluationEnvironment:self];

	return variable;
}

-makeLocalVar:aToken
{
	MPWIdentifierExpression* variable=[[[MPWIdentifierExpression alloc] init] autorelease];
    [variable setOffset:[scanner offset]];
    [variable setLen:1];
	MPWNamedIdentifier *identifier=[[[MPWNamedIdentifier alloc] init] autorelease];
	NSString* name = [aToken stringValue];
	[identifier setIdentifierName:name];
	[identifier setScheme:[self schemeForName:[identifier schemeName]]];
	[variable setIdentifier:identifier];
	[variable setEvaluationEnvironment:self];
	return variable;
}


-objectifyScanned:object
{
//	NSLog(@"objectifyScanned: %@",object);
    if ( [object isEqual:@"#"] ) {
        object = [self parseLiteral];
    } else if ( [object isEqual:@"("] ) {
        id closeParen;
        object = [self parseExpression];
        closeParen=[self nextToken];
		NSAssert1( [closeParen isEqual:@")"], @"'(' not followed by ')': '%@'",closeParen);
    } else if ( [object isEqual:@"["] ) {
        object = [self parseBlock];
    } else if ( [object isEqual:@"-"] ) {
        object = [[self parseLiteral] negated];
    } else if ( [object isToken] && ![[object stringValue] isScheme] ) {
		object = [self makeLocalVar:object];
    } else if ( [object isToken] && [[object stringValue] isScheme] ) {
		object = [self makeComplexIdentifier:object];
	}
    return object;
}

-parseBlockVariables
{
	id variableNames = [NSMutableArray array];
	BOOL keepReading=NO;
	do {
		id possibleColon=[self nextToken];
//		NSLog(@"possibleColon: %@",possibleColon);
		if ( [possibleColon isEqual:@":"] ) {
			id varName = [self nextToken];
			[variableNames addObject:varName];
			keepReading=YES;
		} else {
			keepReading=NO;
			if ( ![possibleColon isEqual:@"|"] ) {
				[self pushBack:possibleColon];
			}
		}
	} while ( keepReading );
	return variableNames;
}

-parseBlock
{
	id statements;
	id closeBrace;
	id blockVariables;
//	NSLog(@"parseBlock");
	blockVariables = [self parseBlockVariables];
//	NSLog(@"block variables: %@",blockVariables);
	statements = [self parseStatements];
	closeBrace=[self nextToken];
//	NSLog(@"done with block: %@",closeBrace);
	NSAssert1( [closeBrace isEqual:@"]"], @"'[' not followed by ']': '%@'",closeBrace);
	id expr = [MPWBlockExpression blockWithStatements:statements arguments:blockVariables];
    [expr setOffset:[scanner offset]];
    [expr setLen:1];
    return expr;
}

-parseArgument
{
    id object=[self nextToken];
	object = [self objectifyScanned:object];
	return object;
}

-parseKeywordOrUnary
{
    id msg;
    msg=[self nextToken];
    if ( [msg isLiteral] ) {
        PARSEERROR(@"invalid message", msg);
    }
    return msg;
}

+(NSDictionary*)specialSelectorMap
{
    static id specialSelectorMap=nil;
    if ( !specialSelectorMap ) {
        specialSelectorMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                                    @"add:", @"+",
                                                                    @"sub:", @"-",
                                                                    @"pipe:", @"|",
                                                                    @"mul:", @"*",
                                                                    @"div:", @"/",
																 @"concat:", @",",
                                                          @"isGreaterThan:", @">",
                                                             @"isLessThan:", @"<",
                                                                @"isEqual:", @"=",
                              @"doAssign:", @":=",
                              @"doAssign:", @"<-",
															  @"pointWith:",@"@",
            nil];
    }
    return specialSelectorMap;
}

-specialSelector:(NSString*)selectorName
{
    return [[[self class] specialSelectorMap] objectForKey:selectorName];
}

-(BOOL)isSpecialSelector:(NSString*)selectorName
{
    return [self specialSelector:selectorName] != nil; 
}

-(SEL)mapSelectorString:(NSString*)selector
{
    SEL sel;
//   NSLog(@"map selector string: %@",selector);
    if ( [self isSpecialSelector:selector] ) {
//        NSLog(@"is special: %@",selector);
        selector = [self specialSelector:selector];
    }
    sel=NSSelectorFromString( selector );
//    NSLog(@"did map to sel %s",sel);
    if (!sel) {
        PARSEERROR(@"unknown message", selector);
    }
    return sel;
}

-parseUnary
{
 //   NSLog(@"parseUnary");
    id expr=[self parseArgument];
    id next=nil;
    while ( nil!=(next=[self nextToken]) && ![next isLiteral] && ![next isKeyword] && ![next isBinary] && ![next isEqual:@")"] && ![next isEqual:@"."] && ![next isEqual:@"]"]) {
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
        [expr setSelector:[self mapSelectorString:next]];
		expr=[self mapConnector:expr]; 
    }
    if ( next ) {
        [self pushBack:next];
    }
    return expr;
}

-parseSelectorAndArgs:expr
{
    id selector=[self parseKeywordOrUnary];
    id args=nil;
//	NSLog(@"parseSelectorAndArgs, selector: '%@'",selector);
    if ( selector && isalpha( *(unsigned char*)[selector bytes] )) {
        BOOL isKeyword =[selector isKeyword];
        if ( isKeyword  ) {
            args=[NSMutableArray array];
            selector=[[selector mutableCopy] autorelease];
            while ( isKeyword ) {
                //---  issue:  the following should really be a full expression parse...
                id arg=[self parseUnary];
                //--- issue:  the above should have been a full expression parse
				id keyword;
//				NSLog(@"in keyword, parsed component: %@",arg);
				[args addObject:arg];
				keyword=[self parseKeywordOrUnary];
                isKeyword=[keyword length] && [keyword isKeyword];
                if ( isKeyword ) {
//					NSLog(@"got more of a keyword: %@",keyword);
                    [selector appendString:keyword];
                } else {
//					NSLog(@"got more of a non-keyword: %@",keyword);
					[self pushBack:keyword];
                    if ( [self isSpecialSelector:keyword] ) {
                        id subExpr = [[[MPWMessageExpression alloc] initWithReceiver:arg] autorelease];
                        [subExpr setOffset:[scanner offset]];
                        [subExpr setLen:1];
                        [self parseSelectorAndArgs:subExpr];
						subExpr=[self mapConnector:subExpr];
                        [args removeLastObject];
                        [args addObject:subExpr];
                    }
				}
            }
        }
    } else {
		if ( [selector isEqual:@":="] || [selector isEqual:@"::="]) {
            PARSEERROR(@"unexpected", selector);
		} else {
            id arg=[self parseUnary];
            if ( arg ) {
                args=[NSArray arrayWithObject:arg];
            } else {
                PARSEERROR(@"argument missing", selector);
            }
		}
//		NSLog(@"parse unary: args=%@",args);
    }
//	NSLog(@"got selector: %@ args: %@",selector,args);
    [expr setSelector:[self mapSelectorString:selector]];
    [expr setArgs:args];
    return expr;
}

-mapConnector:aConnectorExpression
{
//	NSLog(@"map of connector with selector '%@'",NSStringFromSelector([aConnectorExpression selector]));
	return aConnectorExpression;
}


-parseMessageExpression:receiver
{
    
    id expr=receiver;
    id next;
    while ( nil!=(next=[self nextToken]) && ![next isEqual:@"."] && ![next isEqual:@")"]&& ![next isEqual:@"]"]) {
        [self pushBack:next];
        expr=[[[MPWMessageExpression alloc] initWithReceiver:expr] autorelease];
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
//		NSLog(@"message expression with receiver: %@",expr);
        [self parseSelectorAndArgs:expr];
		expr = [self mapConnector:expr];
    }
    if ( next ) {
        [self pushBack:next];
    }
    return expr;
}


-parseAssignmentLikeExpression:lhs withExpressionClass:(Class)assignmentExpressionClass
{
	id rhs = [self parseExpression];
    id assignment = [[[assignmentExpressionClass alloc] init] autorelease];
    [assignment setOffset:[scanner offset]];
    [assignment setLen:1];
//	NSLog(@"have assignment of first: %@",first,assignment);
	[assignment setLhs:lhs];
	[assignment setRhs:rhs];
//	NSLog(@"have assignment rhs: %@",rhs);
	return assignment;
}

-connectorClassForToken:aToken
{
//	NSLog(@"connectorClass for token: '%@' is %@",aToken,[connectorMap objectForKey:aToken]);
	return [connectorMap objectForKey:aToken];
}

-(BOOL)isAssignmentLikeToken:aToken
{
	return [self connectorClassForToken:aToken] != nil;// [aToken isEqual:@":="];
}

-assignmentClassForToken:aToken
{
	return [self connectorClassForToken:aToken];
}

-parseExpression
{
	id first=[self nextToken];
	id second;
	if ( [first isToken] && ![first isEqual:@"-"]  ) {
		first = [self objectifyScanned:first];
		second = [self nextToken];

		if (  [self isAssignmentLikeToken:second]  ) {
//			NSLog(@"assignmentLikeToken: %@",second);
			return [self parseAssignmentLikeExpression:first withExpressionClass:[self connectorClassForToken:second]];
        } else {
			[self pushBack:second];
		}
	} else {
		first = [self objectifyScanned:first];
	}
//	NSLog(@"in parseExpression, about to objectifyScanned:");
//	first = [self objectifyScanned:first];
	second=[self nextToken];
    if ( [second isLiteral] && [first isEqual:@"-"]  && [second isKindOfClass:[NSNumber class]] ) {
        first = [first negated];
        second = [self nextToken];
    }
    if (second)  {		//	potential message expression
//		NSLog(@"got first %@ second %@",first,second);
//		first = [self objectifyScanned:first];
        [self pushBack:second];
        if ( ![second isEqual:@"."] && ![second isEqual:@"("] && ![second isEqual:@"["] ) {
            return [self parseMessageExpression:first];
        }
    }
    return first;
}

-(id)parseStatement
{
    id next=[self nextToken];
    if ( [next isEqual:@"|"]) {
        next=[self nextToken];
        while ( next && ![next isEqual:@"|"]) {
            next=[self nextToken];
        }

    } else {
        [self pushBack:next];
    }
    return [self parseExpression];
}

-parseStatements
{
	id first;
	id next;
	id expression;
	first = [self parseStatement];
	expression=first;
	next = [self nextToken];
	if ( next && [next isEqual:@"."] ) {
		id statements=[MPWStatementList statementList];
		expression=statements;
		[statements addStatement:first];
		while ( next && [next isEqual:@"."] /* || [next isEqual:@";"] */ ) {
			id nextExpression;
			next = [self nextToken];
			if ( next && [next isEqual:@"]"] ) {
				break;
			}
			[self pushBack:next];
			nextExpression=[self parseStatement];
			next = nil;
			if ( nextExpression ) {
				[statements addStatement:nextExpression];
				next=[self nextToken];
			}
		}
	}
	if ( next ) {
//		NSLog(@"parseStatement done, pushing back: %@",next);
		[self pushBack:next];
	}
	return expression;
}

-compile:aString
{
    id expr;
/*
	[self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
	while ( token=[self nextToken] ) {
		[tokenArray addObject:token];
	}
	NSLog(@"tokens: %@",tokenArray);
*/ 
    [self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
    expr = [self parseStatements];
//    NSLog(@"expr = %@",expr);
    return expr;
}

-(BOOL)isValidSyntax:(NSString*)stString
{
    @try {
        id result =[self compile:stString];
        return result!=nil;
    } @catch (id exception) {
    }
    return NO;
}

-bindingForIdentifier:(MPWIdentifier*)anIdentifier
{
	return [[self schemeForName:[anIdentifier schemeName]] bindingWithIdentifier:anIdentifier withContext:self];
}

-bindingForString:(NSString*)fullPath
{
    MPWIdentifier *identifier=nil;
	NSArray *parts=[fullPath componentsSeparatedByString:@":"];
	NSString *schemeName = @"default";
	NSString *path=fullPath;
	if ( [parts count] >= 2 ) {
		schemeName = [parts objectAtIndex:0];
        path=[path substringFromIndex:[schemeName length]+1];
	}
    identifier=[MPWIdentifier identifierWithName:path];

    [identifier setSchemeName:schemeName];
	return [self bindingForIdentifier:identifier];
}

-(void)dealloc
{
    [tokens release];
    [scanner release];
    [super dealloc];
}



@end


@implementation MPWStCompiler(tests)

+(void)testCheckValidSyntax
{
    MPWStCompiler *compiler=[self compiler];
    EXPECTTRUE([compiler isValidSyntax:@" 3+4 "], @"'3+4' valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@" 3+  "], @"'3+' not valid syntax ");
}

+(void)testRightArrowDoesntGenerateMsgExpr
{
    MPWStCompiler *compiler=[self compiler];
    id expr=[compiler compile:@"[ :a | a ] -> stdout"];
    EXPECTFALSE([expr isKindOfClass:[MPWMessageExpression class]], @"'[ :a | a ] -> stdout' is msg expr");
}

+(void)testPipeSymbolForTemps
{
    MPWStCompiler *compiler=[self compiler];
    id expr=[compiler compile:@"| a |"];
    EXPECTNIL(expr, @"expr");
}


+testSelectors
{
    return @[ @"testCheckValidSyntax" ,
              @"testRightArrowDoesntGenerateMsgExpr",
              @"testPipeSymbolForTemps",
              ];
}

@end
