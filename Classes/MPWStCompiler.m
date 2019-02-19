/* MPWStCompiler.m created by marcel on Mon 03-Jul-2000 */

#import "MPWStCompiler.h"
#import "MPWStScanner.h"
#import "MPWMessageExpression.h"
#import "MPWIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWComplexAssignment.h"
#import "MPWStatementList.h"
#import "MPWBlockExpression.h"
#import <MPWFoundation/MPWInterval.h>
#import "MPWMethodStore.h"
#import "MPWIdentifier.h"
#import "MPWRecursiveIdentifier.h"
#import "MPWURLSchemeResolver.h"
#import "MPWFileSchemeResolver.h"
#import "MPWEnvScheme.h"
#import "MPWBundleScheme.h"
//#import "MPWScriptingBridgeScheme.h"
#import "MPWDefaultsScheme.h"
#import "MPWEnvScheme.h"
#import "MPWSchemeScheme.h"
#import "MPWConnectToDefault.h"
#import <MPWFoundation/NSNil.h>
#import "MPWLiteralExpression.h"
#import "MPWCascadeExpression.h"
#import "MPWDataflowConstraintExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWLiteralDictionaryExpression.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWClassDefinition.h"
#import "MPWInstanceVariable.h"
#import "MPWFilterDefinition.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWPropertyPath.h"
#import "MPWPropertyPathComponent.h"

#import "MPWBidirectionalDataflowConstraintExpression.h"

@class MPWClassMethodStore;

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

@implementation NSArray(concat)

-concat:other
{
    return [self arrayByAddingObjectsFromArray:@[ other ]];
}


@end


@implementation MPWStCompiler


objectAccessor( NSMutableDictionary, symbolTable, setSymbolTable)
objectAccessor( MPWStScanner, scanner, setScanner )
objectAccessor( MPWMethodStore, methodStore, setMethodStore )
idAccessor( connectorMap, setConnectorMap );
idAccessor(solver, setSolver)

-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol
{
	[[self connectorMap] setObject:aClass forKey:symbol];
}

-(void)defineBuiltInConnectors
{
    [self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@":="];
    [self defineConnectorClass:[MPWDataflowConstraintExpression class] forConnectorSymbol:@"|="];
    [self defineConnectorClass:[MPWBidirectionalDataflowConstraintExpression class] forConnectorSymbol:@"=|="];
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"\u21e6"];
	[self defineConnectorClass:[MPWComplexAssignment class] forConnectorSymbol:@"\u2190"];
	[self defineConnectorClass:[MPWComplexAssignment class] forConnectorSymbol:@"<-"];
	[self defineConnectorClass:[MPWConnectToDefault class] forConnectorSymbol:@"->"];
	[self defineConnectorClass:[MPWConnectToDefault class] forConnectorSymbol:@"\u21e8"];
	[self defineConnectorClass:[MPWConnectToDefault class] forConnectorSymbol:@"\u2192"];
}

-initWithParent:newParent
{
	self=[super initWithParent:newParent];
	[self setMethodStore:[[[MPWMethodStore alloc] initWithCompiler:self] autorelease]];
	[self setConnectorMap:[NSMutableDictionary dictionary]];
    [self setSolver:[newParent solver]];
	[self defineBuiltInConnectors];
    [self resetSmbolTable];
	return self;
}


#pragma mark MethodDictionary compatibility

-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString
{
    [[self methodStore] addScript:scriptString forClass:className methodHeaderString:methodHeaderString];
}

-(void)addScript:scriptString forMetaClass:className methodHeaderString:methodHeaderString
{
    [[self methodStore] addScript:scriptString forMetaClass:className methodHeaderString:methodHeaderString];
}

-(NSArray*)classesWithScripts
{
	return [[self methodStore] classesWithScripts];
}

-(NSArray*)methodNamesForClassName:(NSString*)aClassName
{
	return [[self methodStore] methodNamesForClassName:aClassName];
}

-(MPWClassMethodStore*)classStoreForName:(NSString*)name
{
    return [[self methodStore] classStoreForName:name];
}

-(NSDictionary*)externalScriptDict
{
	return [[self methodStore] externalScriptDict];
}

-(void)defineMethodsInExternalDict:(NSDictionary*)aDict
{
	[[self methodStore] defineMethodsInExternalDict:aDict];
    [[self methodStore] installMethods];
}

-(void)resetSmbolTable
{
    [self setSymbolTable:[NSMutableDictionary dictionary]];
}


//-methodDictionaryForClassNamed:(NSString*)aName
//{
//    return [[self methodStore] methodDictionaryForClassNamed:aName];
//}

-methodForClass:aClassName name:aMethodName
{
	return [[self methodStore] methodForClass:aClassName name:aMethodName];
}


#pragma mark Evaluator

-(MPWSchemeScheme*)createSchemes
{
	MPWSchemeScheme* schemes=[super createSchemes];
	[schemes setSchemeHandler:[MPWDefaultsScheme store]  forSchemeName:@"defaults"];
	[schemes setSchemeHandler:[MPWFileSchemeResolver store]  forSchemeName:@"file"];
	[schemes setSchemeHandler:[MPWURLSchemeResolver httpScheme]  forSchemeName:@"http"];
	[schemes setSchemeHandler:[MPWURLSchemeResolver httpsScheme]  forSchemeName:@"https"];
    [schemes setSchemeHandler:[[[MPWURLSchemeResolver alloc] initWithSchemePrefix:@"ftp"  ]  autorelease] forSchemeName:@"ftp"];
    
	[schemes setSchemeHandler:[MPWEnvScheme store]  forSchemeName:@"env"];
	[schemes setSchemeHandler:[MPWBundleScheme store]  forSchemeName:@"bundle"];
	[schemes setSchemeHandler:[MPWBundleScheme mainBundleScheme]  forSchemeName:@"mainbundle"];
//	[schemes setSchemeHandler:[MPWScriptingBridgeScheme scheme]  forSchemeName:@"app"];
	
	return schemes;
}




#pragma mark Compiler

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

//-lookupScriptNamed:methodName forClassName:className
//{
//    return [[self methodDictionaryForClassNamed:className] objectForKey:methodName];
//}
//
//-evaluateScriptNamed:methodName onObject:receiver
//{
//    NSString *className=NSStringFromClass([receiver class]);
//    NSString *scriptString=[self lookupScriptNamed:methodName forClassName:className];
//    [self resetSmbolTable];
//    return [self evaluateScript:scriptString onObject:receiver];
//}

-(void)parseError:(NSString*)msg token:(id)token selector:(SEL)sel
{
    NSString *errstr = [NSString stringWithFormat:@"%@ in '%@' %@/%@ from %@",msg,NSStringFromSelector(sel),token,[token class],scanner];
    NSDictionary *errdict =@{
        @"scanner": scanner,
        @"token":  token ?: @"",
        @"mightNeedMoreInput": @(YES),
    };
    
    id e=[NSException exceptionWithName:msg reason:errstr userInfo:errdict];
    @throw e;
    
}

#define PARSEERROR( msg, theToken )  [self parseError:msg token:theToken selector:_cmd]

-(void)untangleConcatsForArrayLiteral:(MPWMessageExpression *)e into:(NSMutableArray *)result
{
    if ( [e isKindOfClass:[MPWMessageExpression class]] && [[e messageName] isEqualToString:@"concat:"]) {
        [self untangleConcatsForArrayLiteral:[e receiver] into:result];
        [self untangleConcatsForArrayLiteral:[[e args] firstObject] into:result];
    } else {
        [result addObject:e];
    }
    
}


-parseLiteralArray
{
//    NSLog(@"parseLiteralArray");
    NSMutableArray *array=[NSMutableArray array];
    id token=nil;
    do {
        token=[self nextToken];
//        NSLog(@"parseLiteralArray, token=%@",token);
        if ( token && !([token isToken] && [token isEqual:@")"]) ) {
//           NSLog(@"inside if token etc.");
            id object=nil;
            if ( [token isEqual:@"#"]) {
                object=[self parseLiteral];
            } else {
//                NSLog(@"not another literal array, push back and parse expression" );
                [self pushBack:token];
                object=[self parseExpressionInLiteral:YES];
                
//                object=[self untangleConcatsForArrayLiteral:object];
                
//                NSLog(@"result of parseExpression: '%@'",object );
            }
//            NSLog(@"will add parsed object: '%@'",object );
            [self untangleConcatsForArrayLiteral:object into:array];
//            NSLog(@"did add parsed object: '%@'",array );
            token=[self nextToken];
//            NSLog(@"get token separator: '%@'",token );
            if ( [token isEqualToString:@","] ) {
//                NSLog(@"comma, continue with loop");
                continue;
            } else if ( [token isEqualToString:@")"] ) {
//                NSLog(@"closing bracket, exit loop");
                break;
            } else {
                PARSEERROR(@"array syntax expr not followed by , or )", @"");
            }
        } else {
            break;
        }
    } while ( YES );
    if ( [token isEqual:@")"] ) {
//        NSLog(@"OK Array found: %@",array);
        MPWLiteralArrayExpression *e=[[MPWLiteralArrayExpression new] autorelease];
        e.objects=array;
        return e;
    } else {
        PARSEERROR(@"array syntax", token);
        return nil;
    }
    LEAVE1;
}

-parseLiteralDict
{
//    NSLog(@"paraseLiteralDict");
    id token=[self nextToken];
//    NSLog(@"first token: %@",token);
    MPWLiteralDictionaryExpression *dictLit=[[MPWLiteralDictionaryExpression new] autorelease];
    [self pushBack:token];
    while ( token && ![token isEqual:@"}"]) {
//        NSLog(@"parse key");
        id key=[self parseExpressionInLiteral:YES];
//        NSLog(@"key: %@",key);
        token=[self nextToken];
//        NSLog(@"separator token: %@",token);
        if (![token isEqual:@":"]) {
            PARSEERROR(@"dictionary syntax: key not folled by ':'  %@", token);
        }
        token=[self nextToken];
        [self pushBack:token];
//        NSLog(@"will parse value with starting token: %@",token);
        id value=[self parseExpressionInLiteral:YES];
//        NSLog(@"value: %@",value);
        [dictLit addKey:key value:value];
        token=[self nextToken];
//        NSLog(@"nextToken: %@",token);
    }
//    NSLog(@"return literal dict: %@",dictLit);
    return dictLit;
}

-parseLiteral
{
    id object = [self nextToken];
    MPWLiteralExpression *e=nil;
    NSString *className=nil;
    id next=[self nextToken];
    if ( [next isEqual:@"("]  || [next  isEqual:@"{"]) {
        className=object;
        object=next;
    } else {
        [self pushBack:next];
    }
    if ( [object isEqual:@"("] ) {
        e = [self parseLiteralArray];
    } else if ( [object isEqual:@"{"] ) {
        e = [self parseLiteralDict];
    } else {
        e=[[MPWLiteralExpression new] autorelease];
        [e setTheLiteral:object];
    }
    if ( className ) {
        [e setClassName:className];
    }
    
    return e;
}



-makeComplexIdentifier:aToken
{
	MPWIdentifierExpression* variable=[[[MPWIdentifierExpression alloc] init] autorelease];
	MPWIdentifier *identifier=[[[MPWIdentifier alloc] init] autorelease];
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
        if (   [lastToken isEqual:@"."] && [name length]>1) {
            [self pushBack:lastToken];
            name=[name substringToIndex:[name length]-1];
        } else if ( [lastToken isEqual:@")"]) {
            [self pushBack:lastToken];
        }
		[scanner setNoNumbers:NO];
	}
	[identifierToAddNameTo setPath:name];
//	[identifier setScheme:[self schemeForName:[identifier schemeName]]];
//	[identifierToAddNameTo setScheme:[self schemeForName:[identifierToAddNameTo schemeName]]];
	[variable setIdentifier:identifier];
	[variable setEvaluationEnvironment:self];

	return variable;
}

-lookupComplexIdentifier:aToken
{
    MPWIdentifierExpression *parsedExpression = [self makeComplexIdentifier:aToken];
    MPWIdentifier *identifier=[parsedExpression identifier];
    NSString *varName = [NSString stringWithFormat:@"%@:%@",[identifier schemeName],[identifier identifierName]];
//    NSLog(@"parsedExpression name: '%@' (expr: %@)",varName,parsedExpression);
    id identifierExpression = [symbolTable objectForKey:varName];
    if (  !identifierExpression && parsedExpression && varName ) {
        identifierExpression=parsedExpression;
        [symbolTable setObject:identifierExpression forKey:varName];
    }
    return identifierExpression;
}

-makeLocalVar:aToken
{
	MPWIdentifierExpression* variable=[[[MPWIdentifierExpression alloc] init] autorelease];
    [variable setOffset:[scanner offset]];
    [variable setLen:1];
	MPWIdentifier *identifier=[[[MPWIdentifier alloc] init] autorelease];
	NSString* name = [aToken stringValue];
	[identifier setPath:name];
//	[identifier setScheme:[self schemeForName:[identifier schemeName]]];
	[variable setIdentifier:identifier];
	[variable setEvaluationEnvironment:self];
	return variable;
}

-lookupLocalVar:anIdentifier
{
    anIdentifier=[anIdentifier stringValue];
    id identifierExpression = [symbolTable objectForKey:anIdentifier];
    if (  !identifierExpression ) {
        identifierExpression=[self makeLocalVar:anIdentifier];
        if ( identifierExpression) {
            [symbolTable setObject:identifierExpression forKey:anIdentifier];
        }
    }
    return identifierExpression;
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
    } else if ( [object isEqual:@"["] || [object isEqual:@"{"] ) {
        object = [self parseBlockWithStart:object];
    } else if ( [object isEqual:@"-"] ) {
        object = [[self parseLiteral] negated];
    } else if ( [object isEqual:@"$"] ) {
        object = [object stringByAppendingString:[[self nextToken] stringValue]];
        object = [self lookupLocalVar:object];
    } else if ( [object isToken] && ![[object stringValue] isScheme] ) {
        object = [self lookupLocalVar:object];
    } else if ( [object isToken] && [[object stringValue] isScheme] ) {
		object = [self lookupComplexIdentifier:object];
	} else if ( [object isKindOfClass:[NSNumber class]] ||  [object isKindOfClass:[NSString class]]){
        MPWLiteralExpression *e=[[MPWLiteralExpression new] autorelease];
        [e setTheLiteral:object];
        object = e;
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

-parseBlockWithStart:(NSString*)startOfBlock
{
	id statements;
	id closeBrace;
	id blockVariables;
    NSString *endOfBlock=[startOfBlock isEqualToString:@"["] ? @"]" : @"}";
//    NSLog(@"parseBlock");
	blockVariables = [self parseBlockVariables];
//	NSLog(@"block variables: %@",blockVariables);
	statements = [self parseStatements];
	closeBrace=[self nextToken];
//	NSLog(@"done with block: %@",closeBrace);
//	NSAssert1( [closeBrace isEqual:@"]"], @"'[' not followed by ']': '%@'",closeBrace);
	id expr = [MPWBlockExpression blockWithStatements:statements arguments:blockVariables];
//    NSLog(@"closeBrace: %@",closeBrace);
    [expr setOffset:[scanner offset]];
    [expr setLen:1];
    if ( ![closeBrace isEqual:endOfBlock] ) {
        NSString *s=[NSString stringWithFormat:@"block not closed by matching '%@'",endOfBlock];
        PARSEERROR(s, expr);
    }
    return expr;
}

-parseArgument
{
    id object=[self nextToken];
	object = [self objectifyScanned:object];
//    NSLog(@"parseArgument -> %@",object);
	return object;
}

-parseKeywordOrUnary
{
    id msg;
    msg=[self nextToken];
    if ( [msg isLiteral] ) {
        PARSEERROR(@"invalid message", msg);
    }
//    NSLog(@"parseKeywordOrUnary msg -> %@",msg);
    return msg;
}

+(NSDictionary*)specialSelectorMap
{
    static id specialSelectorMap=nil;
    if ( !specialSelectorMap ) {
        specialSelectorMap = [[NSDictionary alloc] initWithObjectsAndKeys:
                              @"isLessThanOrEqualTo:", @"\u2264",
                              @"isGreaterThanOrEqualTo:", @"\u2265",
                              @"isNotEqualTo:", @"\u2260",
                              @"add:", @"+",
                              @"sub:", @"-",
                                                                    @"mul:", @"*",
                                                                    @"div:", @"/",
																 @"concat:", @",",
                                                          @"isGreaterThan:", @">",
                                                             @"isLessThan:", @"<",
                              @"isEqual:", @"=",
                              @"doAssign:", @":=",
                              @"doAssign:", @"|=",
                              @"doAssign:", @"=|=",
                              @"doAssign:", @"<-",
                              @"doAssign:", @"\u21e6",
                              @"doAssign:", @"\u2190",
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
//    NSLog(@"parseUnary");
    id expr=[self parseArgument];
//    NSLog(@"argument: %@",expr);
  id next=nil;
    while ( nil!=(next=[self nextToken]) && ![next isLiteral] && ![next isKeyword] && ![next isBinary] && ![next isEqual:@")"] && ![next isEqual:@"."] &&![next isEqual:@";"] &&![next isEqual:@"|"] && ![next isEqual:@"]"]) {
//        NSLog(@"part of parseUnary, token: %@",next);
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
        [expr setSelector:[self mapSelectorString:next]];
		expr=[self mapConnector:expr];
//        NSLog(@"part of parseUnary: %@",expr);
    }
    if ( next ) {
        [self pushBack:next];
    }
//    NSLog(@"parseUnary -> %@",expr);
    return expr;
}

-parseSelectorAndArgs:expr
{
//    NSLog(@"entry parseSelectorAndArgs:");
    id selector=[self parseKeywordOrUnary];
    id args=nil;
//    NSLog(@"parseSelectorAndArgs, selector: '%@'",selector);

    if ( selector && isalpha( [selector characterAtIndex:0] )) {
//        NSLog(@"possibly keyword: '%@'",selector);
        BOOL isKeyword =[selector isKeyword];
        if ( isKeyword   ) {
            args=[NSMutableArray array];
            selector=[[selector mutableCopy] autorelease];
            while ( isKeyword ) {
                //---  issue:  the following should really be a full expression parse...
                id arg=[self parseUnary];
                //--- issue:  the above should have been a full expression parse
				id keyword=nil;
//				NSLog(@"in keyword, parsed component: %@",arg);
                if (arg) {
                    [args addObject:arg];
                    keyword=[self parseKeywordOrUnary];
                    isKeyword=[keyword length] && [keyword isKeyword];
                } else {
                    break;
                }
                if ( isKeyword ) {
//					NSLog(@"got more of a keyword: %@",keyword);
                    [selector appendString:keyword];
                } else {
//					NSLog(@"got more of a non-keyword: %@",keyword);
					[self pushBack:keyword];
                    if ( [self isSpecialSelector:keyword] ) {
//                        NSLog(@"special selector '%@' encountered, parsing subexpression",keyword);
                        id subExpr = [[[MPWMessageExpression alloc] initWithReceiver:arg] autorelease];
                        [subExpr setOffset:[scanner offset]];
                        [subExpr setLen:1];
                        [self parseSelectorAndArgs:subExpr];
						subExpr=[self mapConnector:subExpr];
                        [args removeLastObject];
                        [args addObject:subExpr];
                        id next = [self nextToken];
                        if ( [next isKeyword]) {
                            isKeyword=YES;
                            [selector appendString:next];
                        } else {
                            [self pushBack:next];
                        }

                    } else {
//                        NSLog(@"non-keyword that is not a special selector: %@",keyword);
                    }
                }
            }
        } else {
//            NSLog(@"not keyword");
        }
    } else {
		if ( [selector isEqual:@":="] ||
            [selector isEqual:@"::="] ||
            [selector isEqual:@"=|="] ||
            [selector isEqual:@"|="]) {
            PARSEERROR(@"unexpected", selector);
        } else if ([selector isEqualToString:@":"]){
//            NSLog(@"single ':' as selector");
            [self pushBack:selector];
            return [expr receiver];
        } else {
//            NSLog(@"binary: %@",selector);
            id arg=[self parseUnary];
//            NSLog(@"arg to binary: %@",arg);
            if ( arg ) {
                args=[NSArray arrayWithObject:arg];
            } else {
                PARSEERROR(@"argument missing", selector);
            }
		}
//		NSLog(@"parse unary: selector=%@ args=%@",selector, args);
    }
//	NSLog(@"got selector: %@ args: %@",selector,args);
    [expr setSelector:[self mapSelectorString:selector]];
    [expr setArgs:args];
//    NSLog(@"return expr from parseSelectorAndArgs: %@",expr);
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
    while ( nil!=(next=[self nextToken]) && ![next isEqual:@"."] &&![next isEqual:@";"] &&![next isEqual:@"|"] && ![next isEqual:@")"]&& ![next isEqual:@"]"]&& ![next isEqual:@"}"]) {
        [self pushBack:next];
        expr=[[[MPWMessageExpression alloc] initWithReceiver:expr] autorelease];
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
//		NSLog(@"message expression with receiver: %@",expr);
        expr=[self parseSelectorAndArgs:expr];
        if ( [expr isKindOfClass:[MPWMessageExpression class]]) {
            expr = [self mapConnector:expr];
        } else {
            return expr;
        }
    }
    if ( next ) {
        [self pushBack:next];
    }
    return expr;
}

-parsePipeExpression:firstExpression
{
    id nextToken;
//    NSLog(@"parsePipe: %@",firstExpression);
    while ( (nextToken = [self nextToken]) && [nextToken isEqualToString:@"|"]) {
        
        id expr=[[[MPWMessageExpression alloc] initWithReceiver:firstExpression] autorelease];
//            NSLog(@"next expr start: %@",expr);
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
//            NSLog(@"parse cascade");
        [self parseSelectorAndArgs:expr];
        expr = [self mapConnector:expr];
        firstExpression=expr;
        
    }
    if ( nextToken) {
        [self pushBack:nextToken];
    }
    return firstExpression;
}


-parseCascadeExpression:firstExpression
{
    id nextToken;
    id cascade=[[MPWCascadeExpression new] autorelease];
    [cascade addMessageExpression:firstExpression];
    while ( (nextToken = [self nextToken]) && [nextToken isEqualToString:@";"]) {
        id expr=[[[MPWMessageExpression alloc] initWithReceiver:[firstExpression receiver]] autorelease];
        //            NSLog(@"next expr start: %@",expr);
        [expr setOffset:[scanner offset]];
        [expr setLen:1];
        //            NSLog(@"parse cascade");
        [self parseSelectorAndArgs:expr];
        expr = [self mapConnector:expr];
        [cascade addMessageExpression:expr];
        //            NSLog(@"cascade expression after parsing cascade: %@",expr);
        
    }
    if ( nextToken) {
        [self pushBack:nextToken];
    }
    return cascade;
}

-parseMessageExpressionOrCascade:receiver
{
    id firstExpression = [self parseMessageExpression:receiver];
//    NSLog(@"after parseMessageExpression, looking for cascades: %@",[scanner tokens]);
    id separator=[self nextToken];
    [self pushBack:separator];
    
    if ( [separator isEqualToString:@"|"] ) {
//        NSLog(@"parsePipe");
        firstExpression = [self parsePipeExpression:firstExpression];
    } else if ([separator isEqualToString:@";"]) {
        firstExpression = [self parseCascadeExpression:firstExpression];
    }

    return firstExpression;
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



-parseExpressionInLiteral:(BOOL)inLiteral
{
//    NSLog(@"parseExpression: inLiteral %d",inLiteral);
	id first=[self nextToken];
//    NSLog(@"first: %@",first);
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
	first = [self objectifyScanned:first];
	second=[self nextToken];
    if ( [second isLiteral] && [first isEqual:@"-"]  && [second isKindOfClass:[NSNumber class]] ) {
        first = [first negated];
        second = [self nextToken];
    }
    if (second )  {		//	potential message expression
//		NSLog(@"potential message expression got first %@ second %@",first,second);
//		first = [self objectifyScanned:first];
        [self pushBack:second];
        if ( inLiteral && [second isEqualToString:@","]) {
//            NSLog(@"comma encountered when in literal, return");
//            NSLog(@"comma encountered when in literal, return: %@",first);
            return first;
        }
        if ( ![second isEqual:@"."] && ![second isEqual:@"("] && ![second isEqual:@"["] ) {
            return [self parseMessageExpressionOrCascade:first];
        } else {
            if ( ![second isEqual:@"."]) {
                PARSEERROR(@"message expression expected", second);
            }
        }
    }
//    NSLog(@"return from parseExpression: %@",first);
    return first;
}

-(id)parseExpression
{
    return [self parseExpressionInLiteral:NO];
}

-(id)parseSendResult
{
    id result=[self parseExpression];
    MPWIdentifierExpression* selfReceiver=[[[MPWIdentifierExpression alloc] init] autorelease];
    MPWIdentifier *selfIdentifer=[MPWIdentifier identifierWithName:@"self"];
    [selfReceiver setIdentifier:selfIdentifer];

    MPWMessageExpression *forward=[[[MPWMessageExpression alloc] initWithReceiver:selfReceiver] autorelease];
    [forward setSelector:@selector(forward:)];
    [forward setArgs:@[ result ]];
    return forward;
}

-(id)parseStatement
{
    id next=[self nextToken];

    if ( [next isEqual:@"|"]) {
//        NSLog(@"parseStatement encounted pipe '|'");
        next=[self nextToken];
        while ( next && ![next isEqual:@"|"]) {
            next=[self nextToken];
        }

    } else if ( [next isEqual:@"^"]) {
        return [self parseSendResult];
    } else if ( [next isEqual:@"class"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        return [self parseClassDefinition];
    } else if ( [next isEqual:@"extension"]) {
        //        Currently just a synomym for class
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        return [self parseClassDefinition];
    } else if ( [next isEqual:@"protocol"]) {
        //        Currently just a synomym for class
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        return [self parseProtocolDefinition];
    } else if ( [next isEqual:@"connector"]) {
        //        Currently just a synomym for class
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        return [self parseProtocolDefinition];
    } else if ( [next isEqual:@"notification"]) {
        //        Currently just a synomym for class
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        return [self parseProtocolDefinition];
    } else if ( [next isEqual:@"filter"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        return [self parseClassDefinition];
    } else if ( [next isEqual:@"scheme"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        MPWClassDefinition *schemeDef = [self parseClassDefinition];
        if ( !schemeDef.superclassName ) {
            schemeDef.superclassName=@"MPWScheme";
        }
        return schemeDef;
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
	if ( next && ([next isEqual:@"."] || [first isKindOfClass:[NSArray class]]) ) {
		id statements=[MPWStatementList statementList];
		expression=statements;
		[statements addStatement:first];
		while ( next && [next isEqual:@"."] /* || [next isEqual:@";"] */ ) {
			id nextExpression;
			next = [self nextToken];
			if ( next && ([next isEqual:@"]"] || [next isEqual:@"}"]) ) {
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
    [self resetSmbolTable];
    [self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
    expr = [self parseStatements];
//    NSLog(@"expr = %@",expr);
    return expr;
}

-(MPWScriptedMethod*)parseMethodDefinition:aString
{
    [self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
    return [self parseMethodDefinition];
}

-(MPWScriptedMethod*)parseMethodBodyWithHeader:(MPWMethodHeader*)header
{
    MPWScriptedMethod *method=[[MPWScriptedMethod new] autorelease];
    [method setMethodHeader:header];
    NSString *bodyStart=[self nextToken];
//    NSLog(@"body start: %@",bodyStart);
    id body=[self parseBlockWithStart:bodyStart];
//    NSLog(@"body: %@",body);
//    NSLog(@"statements: %@",statements);
    [method setMethodBody:[body statements]];
    return method;
}

-(MPWScriptedMethod*)parseMethodDefinition
{
    MPWScriptedMethod *method=nil;
    NSString *s=[self nextToken];
    if ( [s isEqualToString:@"-"]) {
        MPWMethodHeader *header=[[[MPWMethodHeader alloc] initWithScanner:[self scanner]] autorelease];
        method=[self parseMethodBodyWithHeader:header];
     }
    
    return method;
}

-(MPWClassDefinition*)parseClassDefinitionFromString:aString
{
    [self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
    return [self parseClassDefinition];
}


-(MPWInstanceVariable *)parseInstanceVariableDefinition
{
    NSString *next=nil;
    if ( [(next=[self nextToken]) isEqualToString:@"var"]) {
        NSString *type=@"id";
        next = [self nextToken];
        if ( [next isEqualToString:@"<"]) {
            type=[self nextToken];
            next=[self nextToken];
            if ( ![next isEqualToString:@">"]) {
                PARSEERROR(@"> expected as close of instance variable definition", next);
            }
        } else {
            [self pushBack:next];
        }
        NSString *name=[self nextToken];
        next=[self nextToken];
        return [[[MPWInstanceVariable alloc] initWithName:name offset:0 type:type] autorelease];
    } else {
        PARSEERROR(@"var expected in instance variable definition", next);
        return nil;
    }
}

-(MPWPropertyPathDefinition *)parsePropertyPathDefinition
{
    MPWPropertyPathDefinition *propertyDef=[[MPWPropertyPathDefinition new] autorelease];
    MPWPropertyPath *path=[[MPWPropertyPath new] autorelease];
    NSMutableArray *identifierComponents=[NSMutableArray array];
    
    NSString *separator=nil;
    do {
        id nextName=[self nextToken];
        MPWPropertyPathComponent* comp=[[MPWPropertyPathComponent new] autorelease];
        if ( [nextName isEqualToString:@"*"] ) {
            comp.isWildcard=YES;
            nextName=[self nextToken];
        }
        if  ([nextName isEqualToString:@":"]  ) {
            nextName=[self nextToken];
            comp.parameter=nextName;
        } else {
            if ( !comp.isWildcard) {
                comp.name=nextName;
            } else {
                [self pushBack:nextName];
            }
        }
        [identifierComponents addObject:comp];
    } while ( (separator=[self nextToken])  &&  [separator isEqualToString:@"/"]);
    [self pushBack:separator];
    path.pathComponents=identifierComponents;
    propertyDef.propertyPath=path;

    NSString *nextToken  = [self nextToken];
//    NSLog(@"nextToken after parse of property header: %@",nextToken);
    if ( [nextToken isEqualToString:@"{"]) {
//        NSLog(@"parse get/set method body");
        nextToken=[self nextToken];
//        NSLog(@"get/set:  %@",nextToken);
        while ( [nextToken isEqualToString:@"|="] || [nextToken isEqualToString:@"=|"]
               || [nextToken isEqualToString:@"=|="]) {
            NSString *getOrSet=nextToken;
            NSArray *formals=[propertyDef.propertyPath formalParameters];
            NSMutableString *s=[@"method" mutableCopy];
            for (NSString *paramName in formals) {
                [s appendFormat:@"Arg:%@ ",paramName];
            }
            if ([getOrSet isEqualToString:@"=|"] ) {
                [s appendString:@"value:newValue "];
            }
            MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:s];
            MPWScriptedMethod* body=[self parseMethodBodyWithHeader:header];
//            NSLog(@"did parse body: %@",body);
            nextToken=[self nextToken];
            
            if ( [getOrSet isEqualToString:@"|="]  ) {
                propertyDef.get=body;
            } else if ( [getOrSet isEqualToString:@"=|"] ) {
                propertyDef.set=body;
            } else {
            }
        }
        if ( ![nextToken isEqualToString:@"}"]) {
            PARSEERROR(@" } to finish get/set property def", nextToken);
        }
        
//        NSLog(@"scanner after parsing property def: %@",[self scanner]);
    } else {
        PARSEERROR(@"expected method body for property def", nextToken);
    }
        
    return propertyDef;
}


-(MPWClassDefinition*)parseClassDefinition
{
    NSString *s=[self nextToken];
    Class defClass=nil;
    if ( [s isEqualToString:@"class"] || [s isEqualToString:@"extension"]) {
        defClass=[MPWClassDefinition class];
    } else  if ( [s isEqualToString:@"scheme"]) {
        defClass=[MPWClassDefinition class];
    } else  if ( [s isEqualToString:@"filter"]) {
        defClass=[MPWFilterDefinition class];
    }
    MPWClassDefinition *classDef=[[defClass new] autorelease];
    if ( classDef ) {
        NSString *name=[self nextToken];
        classDef.name = name;
        NSString *separator=[self nextToken];
        if ( [separator isEqualToString:@":"]) {
            NSString *superclassName=[self nextToken];
            classDef.superclassName=superclassName;
            separator=[self nextToken];
        }
        NSMutableArray *methods=[NSMutableArray array];
        NSMutableArray *instanceVariables=[NSMutableArray array];
        NSMutableArray *propertyDefinitions=[NSMutableArray array];
        if ( [separator isEqualToString:@"{"]) {
            NSString *next=nil;
            while (nil != (next=[self nextToken])) {
//                NSLog(@"token: %@",next);
                if ( [next isEqualToString:@"-"]) {
                    [self pushBack:next];
                    MPWScriptedMethod *method=[self parseMethodDefinition];
                    [methods addObject:method];
                } else if ( [next isEqualToString:@"var"]) {
                    [self pushBack:next];
                    [instanceVariables addObject:[self parseInstanceVariableDefinition]];
                    next=[self nextToken];
                    if ( ![next isEqualToString:@"."]) {
                        [self pushBack:next];
                    }
                } else if ( [next isEqualToString:@"val"]) {
                    PARSEERROR(@"const definitions not supported yet", next);
                } else if ( [next isEqualToString:@"}"]) {
                    break;
                } else if ( [next isEqualToString:@"/"]) {
                    MPWPropertyPathDefinition *prop=[self parsePropertyPathDefinition];
                    [propertyDefinitions addObject:prop];
                    next=[self nextToken];
                    [self pushBack:next];
//                    NSLog(@"nextToken after property parse of %@: %@",[[prop propertyPath] name],next);
                } else {
                    PARSEERROR(@"unexpected symbol in class def, expected method, var or val",next);
                }
            }
            if ( ![next isEqual:@"}"]) {
                PARSEERROR(@"incomplete class definition", @"");
            }
            classDef.methods=methods;
            classDef.instanceVariableDescriptions=instanceVariables;
            classDef.propertyPathDefinitions=propertyDefinitions;
        } else if ( [separator isEqualToString:@"|{"]) {
            MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:@"<void>writeObject:object sender:aSender"];
            [self pushBack:@"{"];
            MPWScriptedMethod *filterMethod=[self parseMethodBodyWithHeader:header];
//            NSLog(@"parsed: %@",filterMethod);
            [methods addObject:filterMethod];
            classDef.methods=methods;
//            NSLog(@"methods: %@",methods);

        } else {
            PARSEERROR(@"expected { in class definition", separator);
        }
    }
    
    return classDef;
}

-(MPWClassDefinition*)parseProtocolDefinition
{
    NSString *s=[self nextToken];
    Class defClass=nil;
    if ( [s isEqualToString:@"protocol"] || [s isEqualToString:@"protocol"] ) {
        defClass=[MPWProtocolDefinition class];
    }
    MPWProtocolDefinition *protoDef=[[defClass new] autorelease];
    if ( protoDef ) {
        NSString *name=[self nextToken];
        protoDef.name = name;
        NSString *separator=[self nextToken];
        if ( [separator isEqualToString:@":"]) {
            NSString *superclassName=[self nextToken];
//            classDef.superclassName=superclassName;
            separator=[self nextToken];
        }
        NSMutableArray *methods=[NSMutableArray array];
        NSMutableArray *instanceVariables=[NSMutableArray array];
        NSMutableArray *propertyDefinitions=[NSMutableArray array];
        if ( [separator isEqualToString:@"{"]) {
            NSString *next=nil;
            while (nil != (next=[self nextToken])) {
                //                NSLog(@"token: %@",next);
                if ( [next isEqualToString:@"-"]) {
                    [self pushBack:next];
                    MPWScriptedMethod *method=[self parseMethodDefinition];
                    [methods addObject:method];
                } else if ( [next isEqualToString:@"var"]) {
                    [self pushBack:next];
                    [instanceVariables addObject:[self parseInstanceVariableDefinition]];
                    next=[self nextToken];
                    if ( ![next isEqualToString:@"."]) {
                        [self pushBack:next];
                    }
                } else if ( [next isEqualToString:@"val"]) {
                    PARSEERROR(@"const definitions not supported yet", next);
                } else if ( [next isEqualToString:@"}"]) {
                    break;
                } else if ( [next isEqualToString:@"/"]) {
                    MPWPropertyPathDefinition *prop=[self parsePropertyPathDefinition];
                    [propertyDefinitions addObject:prop];
                    next=[self nextToken];
                    [self pushBack:next];
                    //                    NSLog(@"nextToken after property parse of %@: %@",[[prop propertyPath] name],next);
                } else {
                    PARSEERROR(@"unexpected symbol in class def, expected method, var or val",next);
                }
            }
            if ( ![next isEqual:@"}"]) {
                PARSEERROR(@"incomplete class definition", @"");
            }
            protoDef.methods=methods;
            protoDef.instanceVariableDescriptions=instanceVariables;
            protoDef.propertyPathDefinitions=propertyDefinitions;
        } else if ( [separator isEqualToString:@"|{"]) {
            MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:@"<void>writeObject:object sender:aSender"];
            [self pushBack:@"{"];
            MPWScriptedMethod *filterMethod=[self parseMethodBodyWithHeader:header];
            //            NSLog(@"parsed: %@",filterMethod);
            [methods addObject:filterMethod];
            protoDef.methods=methods;
            //            NSLog(@"methods: %@",methods);

        } else {
            PARSEERROR(@"expected { in class definition", separator);
        }
    }

    return protoDef;
}


-(id)compileAndEvaluate:(NSString*)aString
{
    return [self evaluateScriptString:aString];
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

-(MPWBinding*)bindingForIdentifier:(MPWIdentifier*)anIdentifier
{
	return [[self schemeForName:[anIdentifier schemeName]] bindingWithIdentifier:anIdentifier withContext:self];
}

-(MPWBinding*)bindingForString:(NSString*)fullPath
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
    [solver release];
    [symbolTable release];
    [super dealloc];
}



@end


@implementation MPWStCompiler(tests)

+(void)testCheckValidSyntax
{
    MPWStCompiler *compiler=[self compiler];
    EXPECTTRUE([compiler isValidSyntax:@" 3+4 "], @"'3+4' valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@" 3+  "], @"'3+' not valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@"42 [  "], @"'42 [ ' not valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@"42 (  "], @"'42 ( ' not valid syntax ");
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


+(void)testSchemeWithDot
{
    MPWStCompiler *compiler=[self compiler];
    MPWIdentifierExpression *expr=[compiler compile:@"doc:."];
    EXPECTTRUE([expr isKindOfClass:[MPWIdentifierExpression class]], @"var:. parses to identifer expression");
    MPWIdentifier *identifier=[expr identifier];
    IDEXPECT([identifier schemeName], @"doc", @"scheme");
    IDEXPECT([identifier identifierName], @".", @"path");
}


+testSelectors
{
    return @[ @"testCheckValidSyntax" ,
              @"testRightArrowDoesntGenerateMsgExpr",
              @"testPipeSymbolForTemps",
              @"testSchemeWithDot",
              ];
}

@end


@implementation NSObject(pipe)

-pipe:other
{
    return self;
}



@end
