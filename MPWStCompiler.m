/* MPWStCompiler.m created by marcel on Mon 03-Jul-2000 */

#import "MPWStCompiler.h"
#import "MPWStScanner.h"
#import "MPWMessageExpression.h"
#import "MPWIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
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

idAccessor( scanner, setScanner )
idAccessor( methodStore, setMethodStore )
idAccessor( connectorMap, setConnectorMap );

-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol
{
	[[self connectorMap] setObject:aClass forKey:symbol];
}

-(void)defineBuiltInConnectors
{
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@":="]; 
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
	[schemes setSchemeHandler:[MPWEnvScheme scheme]  forSchemeName:@"env"];
	[schemes setSchemeHandler:[MPWBundleScheme scheme]  forSchemeName:@"bundle"];
	[schemes setSchemeHandler:[MPWBundleScheme mainBundleScheme]  forSchemeName:@"mainbundle"];
//	[schemes setSchemeHandler:[MPWScriptingBridgeScheme scheme]  forSchemeName:@"app"];
	
	return schemes;
}




//--- true compiler methods

-nextToken
{
	return [scanner nextToken];
}

-(void)pushBack:aToken
{
	[scanner pushBack:aToken];
}

+evaluate:aString
{
    return [[[[self alloc] init] autorelease] evaluateScriptString:aString];
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
	NSString *className=[receiver className];
	NSString *scriptString=[self lookupScriptNamed:methodName forClassName:className];
	return [self evaluateScript:scriptString onObject:receiver];
}

-parseObject
{
    id object=[self nextToken];
    if ( ![object isLiteral] ) {
        [NSException raise:@"invalidobject" format:@"invalid object %@/%@ from %@",object,[object class],scanner];
    }
    return object;
}

-(void)reportError:msg
{
    [NSException raise:msg format:@"%@: scanner: %@",msg,scanner];
}

-parseLiteralArray
{
    NSMutableArray *array=[NSMutableArray array];
    id object;
    do {
        object=[self nextToken];
//        NSLog(@"got object: %@",object);
        if ( object && !([object isToken] && [object isEqual:@")"]) ) {
            [array addObject:[(MPWExpression*)object evaluate]];
        } else {
            break;
        }
    } while ( YES );
    if ( [object isEqual:@")"] ) {
//        NSLog(@"OK Array found: %@",array);
        return array;
    } else {
        [self reportError:@"array syntax"];
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
	scheme=[scheme substringToIndex:[scheme length]-1];
	NSString* name;
	id nextToken=nil;
	if ( YES ) {
		//--- have a scheme
		[identifier setSchemeName:scheme];
		if ( [scheme isEqual:@"ref"] ) {
			MPWIdentifier *nextIdentifier=identifier;
			identifier=[[[MPWRecursiveIdentifier alloc] init] autorelease];
			[identifier setSchemeName:scheme];
			[identifier setNextIdentifier:nextIdentifier];
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
		do {
			nextToken=[self nextToken];
			if (nextToken  ) {
				name=[name stringByAppendingString:[nextToken stringValue]];
			}
		} while (nextToken && ![scanner atSpace] );
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
	return [MPWBlockExpression blockWithStatements:statements arguments:blockVariables];
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
        [NSException raise:@"invalidmsg" format:@"in %@ invalid message %@/%@ from %@",NSStringFromSelector(_cmd),msg,[msg class],scanner];
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

    if ( [self isSpecialSelector:selector] ) {
        selector = [self specialSelector:selector];
    }
    sel=NSSelectorFromString( selector );
    if (!sel) {
        [NSException raise:@"invalidmessage" format:@"message %@ not known",selector];
    }
    return sel;
}

-parseUnary
{
    id expr=[self parseArgument];
    id next=nil;
    while ( nil!=(next=[self nextToken]) && ![next isLiteral] && ![next isKeyword] && ![next isBinary] && ![next isEqual:@")"] && ![next isEqual:@"."] && ![next isEqual:@"]"]) {
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
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
    id selector;
    id args=nil;
	selector=[self parseKeywordOrUnary];
//	NSLog(@"parseSelectorAndArgs, selector: %@",selector);
    if ( selector && isalpha( *(unsigned char*)[selector bytes] )) {
        BOOL isKeyword =[selector isKeyword];
        if ( isKeyword  ) {
            args=[NSMutableArray array];
            selector=[selector mutableCopy];
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
                        id subExpr = [[MPWMessageExpression alloc] initWithReceiver:arg];
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
			[NSException raise:@"unexpected" format:@"not expecting ':=' in parseSelectorAndArgs:"];
		} else {
			args=[NSArray arrayWithObject:[self parseUnary]];
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
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
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
	if ( [first isToken] && ![first isEqual:@"-"] && ![first isEqual:@"["] ) {
		first = [self objectifyScanned:first];
		second = [self nextToken];

		if (  [self isAssignmentLikeToken:second]  ) {
//			NSLog(@"assignmentLikeToken: %@",second);
			return [self parseAssignmentLikeExpression:first withExpressionClass:[self assignmentClassForToken:second]];
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

-parseStatements
{
	id first;
	id next;
	id expression;
	first = [self parseExpression];
	expression=first;
	next = [self nextToken];
	if ( next && [next isEqual:@"."] ) {
		id statements=[MPWStatementList statementList];
		expression=statements;
		[statements addStatement:first];
		while ( next && [next isEqual:@"."] ) {
			id nextExpression;
			next = [self nextToken];
			if ( next && [next isEqual:@"]"] ) {
				break;
			}
			[self pushBack:next];
			nextExpression=[self parseExpression];
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
	if ( ![self scanner] ) {
		[self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
	} else {
		[scanner _setData:nil];
		[scanner addData:[aString asData]];
	}
    expr = [self parseStatements];
//    NSLog(@"expr = %@",expr);
    return expr;
}

-bindingForScheme:(NSString*)schemeName path:(NSString*)path
{
	return [[self schemeForName:schemeName] bindingForName:path inContext:self];
}

-bindingForString:(NSString*)fullPath
{
	NSArray *parts=[fullPath componentsSeparatedByString:@":"];
	NSString *schemeName = @"default";
	NSString *path=[parts lastObject];
	if ( [parts count]==2 ) {
		schemeName = [parts objectAtIndex:0];
	}
	return [self bindingForScheme:schemeName path:path];
}

-(void)dealloc
{
    [tokens release];
    [scanner release];
    [super dealloc];
}

@end



