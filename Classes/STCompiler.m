/* STCompiler.m created by marcel on Mon 03-Jul-2000 */

#import "STCompiler.h"
#import "MPWStScanner.h"
#import "MPWMessageExpression.h"
#import "MPWIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWStatementList.h"
#import "MPWBlockExpression.h"
#import <MPWFoundation/MPWInterval.h>
#import "MPWMethodStore.h"
#import "MPWIdentifier.h"
#import "MPWRecursiveIdentifier.h"
//#import "MPWURLSchemeResolver.h"
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
#import "MPWLiteralDictionaryExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "MPWScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "MPWClassDefinition.h"
#import "MPWInstanceVariable.h"
#import "MPWFilterDefinition.h"
#import "MPWPropertyPathDefinition.h"
#import "MPWPropertyPath.h"
#import "MPWPropertyPathComponent.h"
#import "STObjectTemplate.h"
#import "MPWBidirectionalDataflowConstraintExpression.h"
#import "STTypeDescriptor.h"
#import "STSubscriptExpression.h"
#import "STPortScheme.h"

@class MPWClassMethodStore;

@implementation NSString(concat)

-concat:other
{
	return [self stringByAppendingString:[other stringValue]];
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


@implementation STCompiler


objectAccessor(NSMutableDictionary*, symbolTable, setSymbolTable)
objectAccessor(MPWStScanner*, scanner, setScanner )
objectAccessor(MPWMethodStore*, methodStore, setMethodStore )
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
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"\u2190"];
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"<-"];
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


-parseLiteralArray:(NSString*)closeArrayToken
{
//    NSLog(@"parseLiteralArray");
    NSMutableArray *array=[NSMutableArray array];
    id token=nil;
    do {
        token=[self nextToken];
//        NSLog(@"parseLiteralArray, token=%@",token);
        if ( token && !([token isToken] && [token isEqual:closeArrayToken]) ) {
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
            } else if ( [token isEqualToString:closeArrayToken] ) {
//                NSLog(@"closing bracket, exit loop");
                break;
            } else {
                PARSEERROR(@"array syntax expr not followed by , or ]", @"");
            }
        } else {
            break;
        }
    } while ( YES );
    if ( [token isEqual:closeArrayToken] ) {
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
    id token=[self nextToken];
//    NSLog(@"parseLiteralDict first token: %@",token);
    MPWLiteralDictionaryExpression *dictLit=[[MPWLiteralDictionaryExpression new] autorelease];
//    NSLog(@"before pushback: %@",scanner);
    [self pushBack:token];
//    NSLog(@"after pushback: %@",scanner);
    while ( token && ![token isEqual:@"}"]) {
//        NSLog(@"parse key/val loop, key part, token:%@ scanner:%@",token,scanner);
        id key=nil;
        if ( [token isEqual:@"#"]) {
            [self nextToken];
//            NSLog(@"skipped over token in key, scanner now: %@",scanner);
            key=[[MPWLiteralExpression new] autorelease];
            [key setTheLiteral:[self nextToken]];
//            NSLog(@"got key: %@ scanner now: %@",key,scanner);
        } else {
            key=[self parseExpressionInLiteral:YES];
        }
//        NSLog(@"key:%@",key);
        id literalValueOfKey=[key theLiteral];
//        NSLog(@"literalValueOfKey: '%@'",literalValueOfKey);
        if ( [literalValueOfKey isKindOfClass:[NSString class]] ) {
            NSString *stringKey=(NSString*)literalValueOfKey;
            if ( [stringKey hasSuffix:@":"]) {
//                NSLog(@"compact string key: %@",stringKey);
                [key setTheLiteral:[stringKey substringToIndex:stringKey.length-1]];
            }
        } else {
            token=[self nextToken];
    //        NSLog(@"separator token: %@",token);
            if (![token isEqual:@":"]) {
                PARSEERROR(@"dictionary syntax: key not folled by ':'  %@", token);
            }
        }
        token=[self nextToken];
//        NSLog(@"will parse value with starting token: '%@'",token);
        id value = nil;
        if ( [token isEqual:@"("]) {
            value = [self parseExpressionInLiteral:NO];
            NSString* closeParen=[self nextToken];
            if ( ![closeParen isEqual:@")"] ) {
                PARSEERROR(@"expression in literal value not followed by ')': '%@'", closeParen);
            }
        } else {
            [self pushBack:token];
            value=[self parseExpressionInLiteral:YES];
        }
//        NSLog(@"value: %@",[value theLiteral]);
        [dictLit addKey:key value:value];
        token=[self nextToken];
//        NSLog(@"nextToken: %@",token);
        if ( [token isEqual:@","]) {
            token=[self nextToken];
            [self pushBack:token];
        }
    }
    token = [self nextToken];               // sometimes we haven't consumed to closing brace
    if ( ![token isEqualToString:@"}"]) {
        [self pushBack:token];
    }
//    NSLog(@"return literal dict: %@ scanner now: %@",dictLit,[self scanner]);
    return dictLit;
}

-parseLiteral
{
    id object = [self nextToken];
    if ( [object isEqual:@"#"]) {
        PARSEERROR(@"unexpected # after #", object);
    }
    MPWLiteralExpression *e=nil;
    NSString *className=nil;
    id next=[self nextToken];
    if ( [next isEqual:@"("]  ||[next isEqual:@"["]  || [next  isEqual:@"{"]) {
        className=object;
//        NSLog(@"got a class name: %@",className);
        object=next;
    } else {
        [self pushBack:next];
    }
    if ( [object isEqual:@"("] ) {
        e = [self parseLiteralArray:@")"];
    } else if ( [object isEqual:@"["] ) {
        e = [self parseLiteralArray:@"]"];
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
    [variable setTextOffset:[scanner offset]];
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
//				NSLog(@"ref token with suffix and new scheme: %@",subsequentScheme);
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
    [variable setTextOffset:[scanner offset]];
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
    if ( [object isEqual:@"#"]  ) {
        object = [self parseLiteral];
    } else if ( [object isEqual:@"["] ) {
        object = [self parseLiteralArray:@"]"];
    } else if ( [object isEqual:@"("] ) {
        id closeParen;
        object = [self parseExpression];
        closeParen=[self nextToken];
		NSAssert1( [closeParen isEqual:@")"], @"'(' not followed by ')': '%@'",closeParen);
    } else if ( /* [object isEqual:@"["] || */ [object isEqual:@"{"] ) {
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
    NSString *endOfBlock=@"}";
//    NSLog(@"parseBlock");
	blockVariables = [self parseBlockVariables];
//	NSLog(@"block variables: %@",blockVariables);
	statements = [self parseStatements];
	closeBrace=[self nextToken];
//	NSLog(@"done with block: %@",closeBrace);
//	NSAssert1( [closeBrace isEqual:@"]"], @"'[' not followed by ']': '%@'",closeBrace);
	id expr = [MPWBlockExpression blockWithStatements:statements arguments:blockVariables];
//    NSLog(@"closeBrace: %@",closeBrace);
    [expr setTextOffset:[scanner offset]];
    [expr setLen:1];
    if ( ![closeBrace isEqual:endOfBlock] ) {
        NSString *s=[NSString stringWithFormat:@"block not closed by matching '%@' got '%@' instead",endOfBlock,closeBrace];
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
    while ( nil!=(next=[self nextToken]) && ![next isLiteral] && ![next isKeyword] && ![next isBinary] && ![next isEqual:@")"] && ![next isEqual:@"."] &&![next isEqual:@";"] &&![next isEqual:@"|"] && ![next isEqual:@"]"]&& ![next isEqual:@"["]) {
//        NSLog(@"part of parseUnary, token: %@",next);
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
        [expr setTextOffset:[scanner offset]];
        [expr setLen:1];
        NSAssert1( ![next isEqual:@"["],@"selector shouldn't be open bracket: %@",next);
        [expr setSelector:[self mapSelectorString:next]];
		expr=[self mapConnector:expr];
//        NSLog(@"part of parseUnary: %@",expr);
    }
    if ( next ) {
        if ( [next isEqual:@"["]) {
//            PARSEERROR(@"got a [ in parseUnary", next);
//            [self pushBack:next];
            expr =  [self parseSubscriptExpression:expr];
        } else {
            [self pushBack:next];
        }
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
        NSAssert1( ![selector isEqual:@"["],@"selector shouldn't be open bracket: %@",selector);
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
                        [subExpr setTextOffset:[scanner offset]];
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
            NSAssert1( ![selector isEqual:@"["],@"selector shouldn't be open bracket: %@",selector);
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
    NSAssert1( ![selector isEqual:@"["],@"selector shouldn't be open bracket: %@",selector);
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
    id prev=nil;
    while ( nil!=(next=[self nextToken]) && ![next isEqual:@"."] &&![next isEqual:@";"] &&![next isEqual:@"|"] && ![next isEqual:@")"]&& ![next isEqual:@"]"]&& ![next isEqual:@"}"] && ![next isEqual:@"#"]) {
        [self pushBack:next];
        expr=[[[MPWMessageExpression alloc] initWithReceiver:expr] autorelease];
        [expr setTextOffset:[scanner offset]];
        [expr setLen:1];
//		NSLog(@"message expression with scanner: %@",scanner);
        expr=[self parseSelectorAndArgs:expr];
        if ( [expr isKindOfClass:[MPWMessageExpression class]]) {
            expr = [self mapConnector:expr];
        } else {
            return expr;
        }
        if ( next == prev ) {
            PARSEERROR(@"No Progress in parseMessageExpression", next);
        }
        prev=next;
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
        [expr setTextOffset:[scanner offset]];
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
        if ( ![firstExpression isKindOfClass:[MPWMessageExpression class]]) {
            PARSEERROR(@"first expression of cascade is not a message", nextToken);
        }
        id expr=[[[MPWMessageExpression alloc] initWithReceiver:[firstExpression receiver]] autorelease];
        //            NSLog(@"next expr start: %@",expr);
        [expr setTextOffset:[scanner offset]];
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
    [assignment setTextOffset:[scanner offset]];
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

-parseSubscriptExpression:first
{
    MPWExpression* indexExpr=[self parseExpression];
    id closeBrace=[self nextToken];
    if ( [closeBrace isEqual:@"]"]) {
        STSubscriptExpression *expr=[[STSubscriptExpression new] autorelease];
        expr.receiver=first;
        expr.subscript=indexExpr;
        first=expr;
    } else {
        PARSEERROR(@"indexExpression not closed by ']'", closeBrace);
    }
    return first;
}

-parseExpressionInLiteral:(BOOL)inLiteral
{
//    NSLog(@"parseExpression: inLiteral %d",inLiteral);
	id first=[self nextToken];
//    NSLog(@"-parseExpressionInLiteral first: %@",first);
	id second;
	if ( [first isToken] && ![first isEqual:@"-"]  ) {
//        NSLog(@"get first via objectifyScanned: %@",first);
		first = [self objectifyScanned:first];
//        NSLog(@"got first: %@",first);
//        NSLog(@"fetch second");
		second = [self nextToken];
//        NSLog(@"second: %@",second);
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
    if ( [second isEqual:@"["]) {
        first = [self parseSubscriptExpression:first];
        second = [self nextToken];
        if ([self isAssignmentLikeToken:second] ) {
            return [self parseAssignmentLikeExpression:first withExpressionClass:[self connectorClassForToken:second]];
        }
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
    MPWIdentifier *selfIdentifier=[MPWIdentifier identifierWithName:@"self"];
    [selfReceiver setIdentifier:selfIdentifier];

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
    } else if ( [next isEqual:@"var"]) {
        //        NSLog(@"found a variable definition");
        [self pushBack:next];
        id result = [self parseLocalVariableDefinition];
        return result;
    } else if ( [next isEqual:@"object"]) {
        //        NSLog(@"found a class definition");
        return [self parseObjectTemplate];
    } else if ( [next isEqual:@"extension"]) {
        //        Currently just a synomym for class, because
        //        a class definition will be treated as an
        //        extension if the class already exists
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        return [self parseClassDefinition];
    } else if ( [next isEqual:@"protocol"]) {
        [self pushBack:next];
        return [self parseProtocolDefinition];
    } else if ( [next isEqual:@"connector"]) {
        [self pushBack:next];
        return [self parseProtocolDefinition];
    } else if ( [next isEqual:@"notification"]) {
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
    long startPos=[[self scanner] currentOffset];
    NSString *bodyStart=[self nextToken];
//    NSLog(@"body start: %@",bodyStart);
    id body=[self parseBlockWithStart:bodyStart];
//    NSLog(@"body: %@",body);
//    NSLog(@"statements: %@",statements);
    long endPos=[[self scanner] currentOffset]-1;
    NSString *methodBodyText=[[self scanner] makeTextFrom:startPos to:endPos];
    [method setScript:methodBodyText];
    [method setMethodBody:[body statements]];
    return method;
}

-(MPWScriptedMethod*)parseMethodDefinition
{
    MPWScriptedMethod *method=nil;
    NSString *s=[self nextToken];
    if ( [s isEqualToString:@"-"] || [s isEqualToString:@"+"]) {
        MPWMethodHeader *header=[[[MPWMethodHeader alloc] initWithScanner:[self scanner]] autorelease];
        method=[self parseMethodBodyWithHeader:header];
     }
    
    return method;
}

-(MPWMethodHeader*)parseMethodHeader
{
    MPWMethodHeader *header=nil;
    NSString *s=[self nextToken];
//    NSLog(@"first token: %@",s);
    if ( [s isEqualToString:@"-"]) {
//        NSLog(@"found '-', parse method header");
        header=[[[MPWMethodHeader alloc] initWithScanner:[self scanner]] autorelease];
//        NSLog(@"parsed header: %@",header);
    }
    s=[self nextToken];
//    NSLog(@"token after method header: %@",s);
    if ( [s isEqualToString:@"."] || [s isEqualToString:@"}"]) {

    } else {
        PARSEERROR(@"unexpected token after method header", s);
    }
    return header;
}

-(MPWClassDefinition*)parseClassDefinitionFromString:aString
{
    [self setScanner:[MPWStScanner scannerWithData:[aString asData]]];
    return [self parseClassDefinition];
}

-(MPWInstanceVariable *)parseVariableDefinition:(Class)variableDefClass
{
    NSString *next=nil;
    if ( [(next=[self nextToken]) isEqualToString:@"var"]) {
        NSString *typeName=@"id";
        next = [self nextToken];
        if ( [next isEqualToString:@"<"]) {
            typeName=[self nextToken];
            next=[self nextToken];
            if ( ![next isEqualToString:@">"]) {
                PARSEERROR(@"> expected as close of instance variable definition", next);
            }
        } else {
            [self pushBack:next];
        }
        NSString *name=[self nextToken];
//        next=[self nextToken];   // skip over ".", but that's actually needed
        STTypeDescriptor *type=[STTypeDescriptor descritptorForSTTypeName:typeName];
        return [[[variableDefClass alloc] initWithName:name type:type] autorelease];
    } else {
        PARSEERROR(@"var expected in instance variable definition", next);
        return nil;
    }
}

-(MPWInstanceVariable *)parseInstanceVariableDefinition
{
    return [self parseVariableDefinition:[MPWInstanceVariable class]];
}

-(STVariableDefinition*)parseLocalVariableDefinition
{
    return [self parseVariableDefinition:[STVariableDefinition class]];
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
            [s appendString:@"ref:theRef "];
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

-(STObjectTemplate*)parseObjectTemplate
{
    STObjectTemplate *template=[[STObjectTemplate new] autorelease];
    NSString *name=[self nextToken];
    template.literalClassName = name;
    NSString *separator=[self nextToken];
    if ( [separator isEqualToString:@":"]) {
        NSString *hash=[self nextToken];
        if ( [hash isEqual:@"#"]) {
            template.literal=[self parseLiteral];
        }
    } else {
        PARSEERROR(@"expected separator ':' in object template, got", separator);

    }
    return template;
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
            if ( [superclassName isEqual:@"#"]) {
                NSLog(@"== template class def ===");
//              [self pushBack:superclassName];
                NSLog(@"parse the literal ");
                id result=[self parseLiteral];
                NSLog(@"class with literal dict: %@",result);
                return result;
            }
            classDef.superclassName=superclassName;
            separator=[self nextToken];
        }
        NSMutableArray *methods=[NSMutableArray array];
        NSMutableArray *classMethods=[NSMutableArray array];
        NSMutableArray<MPWInstanceVariable*> *instanceVariables=[NSMutableArray array];
        NSMutableArray *propertyDefinitions=[NSMutableArray array];
        if ( [separator isEqualToString:@"{"]) {
            NSString *next=nil;
            while (nil != (next=[self nextToken])) {
//                NSLog(@"token: %@",next);
                if ( [next isEqualToString:@"-"]) {
                    [self pushBack:next];
                    MPWScriptedMethod *method=[self parseMethodDefinition];
                    [methods addObject:method];
                } else if ( [next isEqualToString:@"+"]) {
                    [self pushBack:next];
                    MPWScriptedMethod *method=[self parseMethodDefinition];
                    [classMethods addObject:method];
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
            classDef.classMethods=classMethods;
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

-(MPWProtocolDefinition*)parseProtocolDefinition
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
//            NSString *superclassName=[self nextToken];
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
                    MPWMethodHeader *method=[self parseMethodHeader];
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
//                    MPWPropertyPathDeclaration *prop=[self parsePropertyPathDeclaration];
//                    [propertyDefinitions addObject:prop];
//                    next=[self nextToken];
//                    [self pushBack:next];
                    //                    NSLog(@"nextToken after property parse of %@: %@",[[prop propertyPath] name],next);
                } else {
                    PARSEERROR(@"unexpected symbol in protocol def, expected method, var or val",next);
                }
            }
            if ( ![next isEqual:@"}"]) {
                PARSEERROR(@"incomplete protocol definition", @"");
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

-(void)defineMethodsForClassDefinition:(MPWClassDefinition*)classDefinition
{
    MPWClassMethodStore* store= [self classStoreForName:classDefinition.name];
    for ( MPWScriptedMethod *method in [classDefinition allMethods]) {
        [store installMethod:method];
    }
    if ( classDefinition.classMethods.count) {
        for ( MPWScriptedMethod *method in [classDefinition classMethods]) {
            [store installClassMethod:method];
        }
    }
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


@implementation STCompiler(tests)

+(void)testCheckValidSyntax
{
    STCompiler *compiler=[self compiler];
    EXPECTTRUE([compiler isValidSyntax:@" 3+4 "], @"'3+4' valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@" 3+  "], @"'3+' not valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@"42 {  "], @"'42 { ' not valid syntax ");
    EXPECTFALSE([compiler isValidSyntax:@"42 (  "], @"'42 ( ' not valid syntax ");
}

+(void)testRightArrowDoesntGenerateMsgExpr
{
    STCompiler *compiler=[self compiler];
    id expr=[compiler compile:@"{ :a | a } -> stdout"];
    EXPECTFALSE([expr isKindOfClass:[MPWMessageExpression class]], @"'{ :a | a } -> stdout' is msg expr");
}

+(void)testPipeSymbolForTemps
{
    STCompiler *compiler=[self compiler];
    id expr=[compiler compile:@"| a |"];
    EXPECTNIL(expr, @"expr");
}


+(void)testSchemeWithDot
{
    STCompiler *compiler=[self compiler];
    MPWIdentifierExpression *expr=[compiler compile:@"doc:."];
    EXPECTTRUE([expr isKindOfClass:[MPWIdentifierExpression class]], @"var:. parses to identifier expression");
    MPWIdentifier *identifier=[expr identifier];
    IDEXPECT([identifier schemeName], @"doc", @"scheme");
    IDEXPECT([identifier identifierName], @".", @"path");
}

+(void)testParsingMethodBodyPreservesSource
{
    STCompiler *compiler=[self compiler];
    [compiler evaluateScriptString:@"class  MPWMethodSourceCompilerTestClass1 : NSObject { -answer { 42. } }. "];
    MPWScriptedMethod *method=[[compiler methodStore] methodForClass:@"MPWMethodSourceCompilerTestClass1" name:@"answer"];
    EXPECTNOTNIL(method, @"got a method");
    IDEXPECT([method script], @" 42. ",@"body");
}

+(void)testParsingPartialNestedLiteralsDoesNotHang
{
    
    NSString *partialNested=@"# #UILabel{ #'text' : 'Hi' }.";
    STCompiler *compiler=[self compiler];
    @try {
        [compiler compile:partialNested];
    } @catch ( NSException* exception ) {
        IDEXPECT([exception name],@"unexpected # after #",@"should be syntax error");
    }
}

+(void)testParsingObjectLiteral
{
    
    NSString *objectLiteral=@"#UILabel{ #text: 'Hi' }";
    STCompiler *compiler=[self compiler];
    MPWLiteralDictionaryExpression *literal=[compiler compile:objectLiteral];
    IDEXPECT(literal.literalClassName, @"UILabel", @"parsed literal class name");
}


+(void)testParseSimpleLiteralDictWithSimplifiedStringKey
{
    NSDictionary *result=[[self compiler] evaluateScriptString:@"#{ #a: 3 }"];
    INTEXPECT(result.count, 1, @"one element");
    IDEXPECT( result[@"a"], @(3), @"contents");
}

+(void)testBasicConnectionExpressionIsParsed
{
    NSString *testProgram =@"source → stdout";
    STCompiler *compiler=[self compiler];
    [compiler evaluateScriptString:@"source ← #MPWFixedValueSource{}"];
    id compiled = [compiler compile:testProgram];
    EXPECTTRUE([compiled isKindOfClass:[MPWConnectToDefault class]], @"connector expr. should be top level");
}

+(void)testParsingConnectedObjectLiterals
{
    // same as BasicConnectionExpression, but without the temporary
    NSString *testProgram =@"#MPWFixedValueSource{  } -> stdout";

    STCompiler *compiler=[self compiler];
    id compiled = [compiler compile:testProgram];
    EXPECTTRUE([compiled isKindOfClass:[MPWConnectToDefault class]], @"connector expr. should be top level");
}

+(void)testObjectLiteralsCanBeUsedInSimpleArithmeticExpressions
{
    id result=[[self compiler] evaluateScriptString:@"#MPWInteger{ #intValue: 3 } +  #MPWInteger{ #intValue: 7 }"];
    INTEXPECT( [result intValue], 10, @"result of add");
}

+(void)testExpressionsInLiterals
{
    id result=[[self compiler] evaluateScriptString:@"#MPWInteger{ #intValue:  ( 3+4 ) }"];
    INTEXPECT( [result intValue], 7, @"result of add");
}

+(void)testInstanceVarHasTypeInformation
{
    NSString *script=@"class Hi { var untyped. var <id> idtyped. var <int> inttyped. var <float> floattyped. } ";
    MPWClassDefinition* classDef=[[self compiler] compile:script];
    NSArray<MPWInstanceVariable*> *ivars=[classDef instanceVariableDescriptions];
    INTEXPECT( ivars.count, 4, @"number of ivars");
    IDEXPECT( ivars[0].type.name, @"id", @"untyped defaults to id");
    IDEXPECT( ivars[0].objcType, @"@", @"untyped defaults to id");
    IDEXPECT( ivars[1].type.name, @"id", @"id type");
    IDEXPECT( ivars[1].objcType, @"@", @"id type");
    IDEXPECT( ivars[2].type.name, @"int", @"int type");
    IDEXPECT( ivars[2].objcType, @"l", @"int type");
    IDEXPECT( ivars[3].type.name, @"float", @"float type");
    IDEXPECT( ivars[3].objcType, @"d", @"float type");
}

+(void)testInstanceVarsOfDefinedClassHaveTypeInformation
{
    NSString *script=@"class __STIvarTypeTestClass { var untyped. var <id> idtyped. var <int> inttyped. var <float> floattyped. } ";
    Class classDef=[[self compiler] evaluateScriptString:script];
    Ivar untyped = class_getInstanceVariable(classDef, "untyped");
    IDEXPECT( @(ivar_getName(untyped)), @"untyped",@"name of 'untyped'");
    IDEXPECT( @(ivar_getTypeEncoding(untyped)), @"@",@"type of 'untyped'");
    Ivar idtyped = class_getInstanceVariable(classDef, "idtyped");
    IDEXPECT( @(ivar_getName(idtyped)), @"idtyped",@"name of 'idtyped'");
    IDEXPECT( @(ivar_getTypeEncoding(idtyped)), @"@",@"objc type of 'idtyped'");
    Ivar inttyped = class_getInstanceVariable(classDef, "inttyped");
    IDEXPECT( @(ivar_getName(inttyped)), @"inttyped",@"name of 'inttyped'");
    IDEXPECT( @(ivar_getTypeEncoding(inttyped)), @"l",@"objc type of 'inttyped'");
}

+(void)testLocalVariableDeclarationParses
{
    id result=[[self compiler] compile:@"class Hi { -hi { var hi. 3+4. } }"];
    EXPECTNOTNIL(result, @"parse result");
}

+(void)testLocalVariableDeclarationEvaluates
{
    NSNumber* result=[[self compiler] evaluateScriptString:@"class Hi { -hi { var <int> hi. 5+4. } }. Hi new hi."];
    INTEXPECT(result.intValue,9, @"result of 5+4, variable declation doesn't do anything");
}

+(void)testLiteralArraysCanHaveSquareBrackets
{
    NSArray* result=[[self compiler] evaluateScriptString:@" [ 1,6,2,'hello']"] ;
    IDEXPECT( result, (@[@(1),@(6),@(2),@"hello"]), @"literal array with square brackets");
}

+(void)testSquareBracketLiteralArraysCanHaveCustomClasses
{
    NSMutableArray* result=[[self compiler] evaluateScriptString:@" #NSMutableArray[ 1,6,2,'hello']"] ;
    result[2]=@"World";
    IDEXPECT( result, (@[@(1),@(6),@"World",@"hello"]), @"literal array with square brackets");
}

+(void)testCanAccessArraysWithSquareBrackets
{
    NSNumber* result=[[self compiler] evaluateScriptString:@"a := [ 1,6,2,'hello']. a[1]."] ;
    IDEXPECT( result, @(6), @"square-bracket array access");
}

+(void)testArrayAccessDoesNotStopEvaluation
{
    NSNumber* result=[[self compiler] evaluateScriptString:@"a := [ 1,6,2,'hello']. a[1]+10."] ;
    IDEXPECT( result, @(16), @"square-bracket array access as start of expression");
}

+(void)testHexLiteral
{
    IDEXPECT( [self evaluate:@"0xff"], @(255), @"hex constant");
    IDEXPECT( [self evaluate:@"0x1a"], @(26), @"hex constant");
}

+(void)testBinaryLiteral
{
    IDEXPECT( [self evaluate:@"0b1001"], @(9), @"binary constant");
    IDEXPECT( [self evaluate:@"0b1111"], @(15), @"binary constant");
}

+testSelectors
{
    return @[ @"testCheckValidSyntax" ,
              @"testRightArrowDoesntGenerateMsgExpr",
              @"testPipeSymbolForTemps",
              @"testSchemeWithDot",
              @"testParsingMethodBodyPreservesSource",
              @"testParsingPartialNestedLiteralsDoesNotHang",
              @"testParseSimpleLiteralDictWithSimplifiedStringKey",
              @"testBasicConnectionExpressionIsParsed",
              @"testParsingObjectLiteral",
              @"testParsingConnectedObjectLiterals",
              @"testObjectLiteralsCanBeUsedInSimpleArithmeticExpressions",
              @"testExpressionsInLiterals",
              @"testInstanceVarHasTypeInformation",
              @"testInstanceVarsOfDefinedClassHaveTypeInformation",
              @"testLocalVariableDeclarationParses",
              @"testLocalVariableDeclarationEvaluates",
              @"testSquareBracketLiteralArraysCanHaveCustomClasses",
              @"testCanAccessArraysWithSquareBrackets",
              @"testArrayAccessDoesNotStopEvaluation",
              @"testHexLiteral",
              @"testBinaryLiteral",
    ];
}

@end


@implementation NSObject(pipe)

-pipe:other
{
    return self;
}



@end


id objs_get_scheme_reference(NSString *schemeName, NSString *reference )
{
    return [(MPWScheme*)[[MPWSchemeScheme currentScheme] at:schemeName] get:reference];
}

