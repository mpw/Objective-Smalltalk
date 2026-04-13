/* STCompiler.m created by marcel on Mon 03-Jul-2000 */

#import "STCompiler.h"
#import "STScanner.h"
#import "MPWMessageExpression.h"
#import "STIdentifierExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWStatementList.h"
#import "MPWBlockExpression.h"
#import <MPWFoundation/MPWInterval.h>
#import "MPWMethodStore.h"
#import "STIdentifier.h"
#import "MPWRecursiveIdentifier.h"
//#import "MPWURLSchemeResolver.h"
#import "MPWFileSchemeResolver.h"
#import "MPWEnvScheme.h"
#import "MPWBundleScheme.h"
//#import "MPWScriptingBridgeScheme.h"
#import "MPWDefaultsScheme.h"
#import "MPWEnvScheme.h"
#import "MPWSchemeScheme.h"
#import "STConnectionDefiner.h"
#import <MPWFoundation/NSNil.h>
#import "MPWLiteralExpression.h"
#import "MPWCascadeExpression.h"
#import "MPWDataflowConstraintExpression.h"
#import "MPWLiteralDictionaryExpression.h"
#import "MPWLiteralArrayExpression.h"
#import "STScriptedMethod.h"
#import "MPWMethodHeader.h"
#import "STPropertyMethodHeader.h"
#import "STClassDefinition.h"
#import "MPWInstanceVariable.h"
#import "STFilterDefinition.h"
#import "STPropertyPathDefinition.h"
#import "STObjectTemplate.h"
#import "MPWBidirectionalDataflowConstraintExpression.h"
#import "STTypeDescriptor.h"
#import "STSubscriptExpression.h"
#import "STPortScheme.h"
#import "STNotificationDefinition.h"
#import "STPostExpression.h"

#define PARSEERROR( msg, theToken )  [self parseError:msg token:theToken selector:_cmd]
#define TRACE( msg, theObjArg )  [self trace:msg obj:theObjArg selector:_cmd]
#define ENTER1(obj)              TRACE(@"ENTER",obj)
#define ENTER                    TRACE(@"ENTER",nil)
#define LEAVE1(obj)              TRACE(@"LEAVE",obj)
#define LEAVE                    TRACE(@"LEAVE",nil)


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

@interface STCompiler()

@property (nonatomic, strong) NSMutableDictionary <NSString*,STClassDefinition*> *classes;

@end


@implementation STCompiler


objectAccessor(NSMutableDictionary*, symbolTable, setSymbolTable)
objectAccessor(STScanner*, scanner, setScanner )
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
    [self defineConnectorClass:[STPostExpression class] forConnectorSymbol:@"+="];
    [self defineConnectorClass:[MPWDataflowConstraintExpression class] forConnectorSymbol:@"|="];
    [self defineConnectorClass:[MPWBidirectionalDataflowConstraintExpression class] forConnectorSymbol:@"=|="];
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"\u21e6"];
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"\u2190"];
	[self defineConnectorClass:[MPWAssignmentExpression class] forConnectorSymbol:@"<-"];
	[self defineConnectorClass:[STConnectionDefiner class] forConnectorSymbol:@"->"];
	[self defineConnectorClass:[STConnectionDefiner class] forConnectorSymbol:@"\u21e8"];
	[self defineConnectorClass:[STConnectionDefiner class] forConnectorSymbol:@"\u2192"];
}

-initWithParent:newParent
{
	self=[super initWithParent:newParent];
	[self setMethodStore:[[[MPWMethodStore alloc] initWithCompiler:self] autorelease]];
	[self setConnectorMap:[NSMutableDictionary dictionary]];
    [self setSolver:[newParent solver]];
	[self defineBuiltInConnectors];
    [self resetSmbolTable];
    self.classes = [NSMutableDictionary dictionary];
    self.closingBraceLiteralDictHack = false;
	return self;
}

-(STClassDefinition*)classForName:(NSString *)className
{
    return self.classes[className];
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

-(void)trace:(NSString*)msg obj:(id)token selector:(SEL)sel
{
    if (self.trace) {
        NSString* tokenString=token ? [NSString stringWithFormat:@" %@/%@",token,[token class]] : @"";
        NSString* pushBackTokens = @"";
        NSArray *pushed=[scanner tokens];
        if ( pushed.count > 0) {
            pushBackTokens = [NSString stringWithFormat:@" %d pushback tokens: '%@' ",pushed.count, [pushed componentsJoinedByString:@","]];
        }
        NSString* errstr = [NSString stringWithFormat:@"%@ in '%@' %@ pushback tokens: '%@' context %@",msg,NSStringFromSelector(sel),tokenString,pushBackTokens, scanner];
        fprintf(stderr,"%s\n",[errstr UTF8String]);
    }
}


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
    ENTER1(closeArrayToken);
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
    LEAVE;
}

-parseLiteralDict
{
    ENTER;
    BOOL closed=NO;
    id token=[self nextToken];
    TRACE( @"first token", token );
    MPWLiteralDictionaryExpression *dictLit=[[MPWLiteralDictionaryExpression new] autorelease];
    if ( ![token isEqual:@"}"]) {
        [self pushBack:token];
    }
    while ( token && ![token isEqual:@"}"]) {
//        NSLog(@"parse key/val loop, key part, token:%@ scanner:%@",token,scanner);
        id key=nil;
        if ( [token isEqual:@"#"]) {
            [self nextToken];
        }
        if (1) {
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
            TRACE(@"separator",token);
    //        NSLog(@"separator token: %@",token);
            if (![token isEqual:@":"]) {
                PARSEERROR(@"dictionary syntax: key not folled by ':'  %@", token);
            }
        }
        token=[self nextToken];
        TRACE(@"first token of value",token);
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

        if ( [token isEqual:@","]) {
            token=[self nextToken];
            [self pushBack:token];
        }
    }
    TRACE(@"closing token after loop",token);
    if ( [token isEqual:@"}"]) {
        closed=YES;
    } else {
        TRACE(@"fell off end in parseLiteralDict?",token);
    }
    // HACK:  sometimes we seem to not read the closing '}'
    //        so we try to read it here by reading again.
    //        However, this hack makes other things not work
    //        so it needs to removed.
    if ( self.closingBraceLiteralDictHack ) {
        token = [self nextToken];    // sometimes this will be the } we forgot to get, but with nested dicts it will be the nesting
        if ( [token isEqualToString:@"}"]) {
            TRACE(@"it was a closing token",token);
            closed = YES;
        } else {
            [self pushBack:token];
        }
    }
    if (!closed) {
        PARSEERROR(@"literal expression should be closed", token);
    }

    LEAVE1( dictLit );
    return dictLit;
}

-parseLiteral
{
    ENTER;
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
    TRACE(@"token to decide the literal",object);
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
	STIdentifierExpression* variable=[[[STIdentifierExpression alloc] init] autorelease];
	STIdentifier *identifier=[[[STIdentifier alloc] init] autorelease];
	STIdentifier *identifierToAddNameTo=identifier;
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
			STIdentifier *nextIdentifier=identifier;
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
//	[variable setEvaluationEnvironment:self];

	return variable;
}

-lookupComplexIdentifier:aToken
{
    STIdentifierExpression *parsedExpression = [self makeComplexIdentifier:aToken];
    STIdentifier *identifier=[parsedExpression identifier];
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
	STIdentifierExpression* variable=[[[STIdentifierExpression alloc] init] autorelease];
    [variable setTextOffset:[scanner offset]];
    [variable setLen:1];
	STIdentifier *identifier=[[[STIdentifier alloc] init] autorelease];
	NSString* name = [aToken stringValue];
	[identifier setPath:name];
//	[identifier setScheme:[self schemeForName:[identifier schemeName]]];
	[variable setIdentifier:identifier];
//	[variable setEvaluationEnvironment:self];
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
    TRACE( @"enter with object: ", object );
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
    TRACE( @"return with object: ", object );

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
                              @"writeObject:", @"!",
                              @"nextObject", @"?",
                              @"sendmsg", @"!!",
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
    TRACE(@"enter",@"");
//    NSLog(@"parseUnary, scanner: %@",scanner);
    MPWMessageExpression* expr=[self parseArgument];
//    NSLog(@"parseUnary expr: %@ scanner: %@",expr,scanner);
    id next=nil;
    while ( nil!=(next=[self nextToken]) && ![next isLiteral] && ![next isKeyword] && ![next isBinary] && ![next isEqual:@")"] && ![next isEqual:@"."] &&![next isEqual:@";"] &&![next isEqual:@"|"] && ![next isEqual:@"]"]&& ![next isEqual:@"}"]&& ![next isEqual:@"["]) {
        expr=[[MPWMessageExpression alloc] initWithReceiver:expr];
        [expr setTextOffset:[scanner offset]];
        [expr setLen:1];
//        NSLog(@"found unary");
        NSAssert1( ![next isEqual:@"["],@"selector shouldn't be open bracket: %@",next);
        [expr setSelector:[self mapSelectorString:next]];
        [expr setNonMappedMessageName:next];
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
    TRACE(@"return",expr);

    return expr;
}

-parseSelectorAndArgs:expr
{
    TRACE(@"entry expr:",expr);
    id selector=[self parseKeywordOrUnary];
    id args=nil;
    TRACE(@"selector:",selector);

    if ( selector && isalpha( [selector characterAtIndex:0] )) {
        TRACE(@"possibly keyword:",selector);
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
                TRACE(@"in keyword, parsed component:",arg);
                if (arg) {
                    [args addObject:arg];
                    keyword=[self parseKeywordOrUnary];
                    isKeyword=[keyword length] && [keyword isKeyword];
                } else {
                    break;
                }
                if ( isKeyword ) {
                    TRACE(@"got more of a keyword:",keyword);
                    [selector appendString:keyword];
                } else {
                    TRACE(@"got more of a non-keyword (push back):",keyword);
					[self pushBack:keyword];
                    if ( [self isSpecialSelector:keyword] ) {
                        TRACE(@"special selector:",keyword);
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
        } else if ([selector isEqualToString:@"!!"]){
            TRACE(@"!! for expr",expr);
            [expr setSelector:[self mapSelectorString:selector]];
            [expr setNonMappedMessageName:selector];
            [expr setArgs:@[]];
            return expr;
        } else if ([selector isEqualToString:@"?"]){
            TRACE(@"? for expr",expr);
            [expr setSelector:[self mapSelectorString:selector]];
            [expr setNonMappedMessageName:selector];
            [expr setArgs:@[]];
            return expr;
        } else {
            if ( [selector isEqual:@"["]) {
                NSLog(@"selector shouldn't be open bracket:\%@",[NSThread callStackSymbols]);
                PARSEERROR(@"selector shouldn't be open bracket", selector);
            }
            TRACE(@"binary",selector);
            id arg=[self parseUnary];
            TRACE(@"arg to binary",arg);
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
    [expr setNonMappedMessageName:selector];
    [expr setArgs:args];
    TRACE(@"return",expr);
    return expr;
}

-mapConnector:aConnectorExpression
{
//	NSLog(@"map of connector with selector '%@'",NSStringFromSelector([aConnectorExpression selector]));
	return aConnectorExpression;
}


-parseMessageExpression:receiver
{
//    NSLog(@"parseMessageExpression: receiver = '%@'",receiver);
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
//    NSLog(@" parseMessageExpressionOrCascade, receiver: %@",receiver);
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
    ENTER1( lhs );
	id rhs = [self parseExpression];
    TRACE(@"did parse potential RHS", rhs );
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
    STExpression* indexExpr=[self parseExpression];
    id closeBrace=[self nextToken];
    if ( [closeBrace isEqual:@"]"]) {
        STSubscriptExpression *expr=[[STSubscriptExpression new] autorelease];
        expr.receiver=first;
        expr.subscript=indexExpr;
        first=[expr convertToQueryIfNecessary]; 
    } else {
        PARSEERROR(@"indexExpression not closed by ']'", closeBrace);
    }
    return first;
}

-parseExpressionInLiteral:(BOOL)inLiteral
{
    ENTER1(@(inLiteral));
	id first=[self nextToken];
    while ( [first isComment] ) {
        TRACE(@"comment",first);
        first=[self nextToken];
//        NSLog(@"next token after comment: %@",first);
    }
    TRACE(@"first", first);
	id second;
	if ( [first isToken] && ![first isEqual:@"-"]  ) {

		first = [self objectifyScanned:first];
        TRACE(@"first via objectifyScanned", first);
		second = [self nextToken];
        TRACE(@"second", second);
		if (  [self isAssignmentLikeToken:second]  ) {
//			NSLog(@"assignmentLikeToken: %@",second);
			return [self parseAssignmentLikeExpression:first withExpressionClass:[self connectorClassForToken:second]];
        } else {
			[self pushBack:second];
		}
	} else {
		first = [self objectifyScanned:first];
	}
	first = [self objectifyScanned:first];
    TRACE(@"first tokeen converted to object",first);
	second=[self nextToken];
    TRACE(@"second token",second);
    if ( [second isLiteral] && [first isEqual:@"-"]  && [second isKindOfClass:[NSNumber class]] ) {
        first = [first negated];
        second = [self nextToken];
        TRACE(@"negation",first);
    }
    if ( [second isEqual:@"["]) {
        TRACE(@"possible subscript with first part",first);
        first = [self parseSubscriptExpression:first];
        second = [self nextToken];
        if ([self isAssignmentLikeToken:second] ) {
            return [self parseAssignmentLikeExpression:first withExpressionClass:[self connectorClassForToken:second]];
        }
        first = [self objectifyScanned:first];
    }
    if (second && [second length] > 0)  {		//	potential message expression
        TRACE(@"potential message expression",second);
        [self pushBack:second];
        if ( inLiteral && [second isEqualToString:@","]) {
            TRACE(@"comma encountered when in literal, return: ",first);
            return first;
        }
        if (  ![second isEqual:@"."] && ![second isEqual:@"("] && ![second isEqual:@"["] ) {
            return [self parseMessageExpressionOrCascade:first];
        } else {
            if ( ![second isEqual:@"."]) {
                PARSEERROR(@"message expression expected", second);
            }
        }
    }
    LEAVE1( first );
    return first;
}

-(id)parseExpression
{
    return [self parseExpressionInLiteral:NO];
}

-(id)parseSendResult
{
    id result=[self parseExpression];
    STIdentifierExpression* selfReceiver=[[[STIdentifierExpression alloc] init] autorelease];
    STIdentifier *selfIdentifier=[STIdentifier identifierWithName:@"self"];
    [selfReceiver setIdentifier:selfIdentifier];

    MPWMessageExpression *forward=[[[MPWMessageExpression alloc] initWithReceiver:selfReceiver] autorelease];
    [forward setSelector:@selector(forward:)];
    [forward setNonMappedMessageName:@"forward"];
    [forward setArgs:@[ result ]];
    return forward;
}

-(id)parseStatement
{
    ENTER;
    id next=[self nextToken];
    id parsedStatement = nil;
    
    if ( [next isEqual:@"|"]) {
        TRACE(@"pipe found",next);
//        NSLog(@"parseStatement encounted pipe '|'");
        next=[self nextToken];
        while ( next && ![next isEqual:@"|"]) {
            next=[self nextToken];
        }
        TRACE(@"after pipe",next);
        parsedStatement =   [self parseExpression];
    } else if ( [next isEqual:@"^"]) {
        parsedStatement =   [self parseSendResult];
    } else if ( [next isEqual:@"class"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        parsedStatement =   [self parseClassDefinition];
    } else if ( [next isEqual:@"var"]) {
        //        NSLog(@"found a variable definition");
        [self pushBack:next];
        id result = [self parseLocalVariableDefinition];
        parsedStatement =   result;
    } else if ( [next isEqual:@"object"]) {
        //        NSLog(@"found a class definition");
        parsedStatement =   [self parseObjectTemplate];
    } else if ( [next isEqual:@"extension"]) {
        //        Currently just a synomym for class, because
        //        a class definition will be treated as an
        //        extension if the class already exists
        //        NSLog(@"found an extension definition");
        [self pushBack:next];
        parsedStatement =   [self parseClassDefinition];
    } else if ( [next isEqual:@"protocol"]) {
        parsedStatement =   [self parseProtocolDefinitionWithClass:[STProtocolDefinition class]];
    } else if ( [next isEqual:@"connector"]) {
        parsedStatement =   [self parseProtocolDefinitionWithClass:[STConnectionDefinition class]];
    } else if ( [next isEqual:@"notification"]) {
        parsedStatement =   [self parseProtocolDefinitionWithClass:[STNotificationDefinition class]];
    } else if ( [next isEqual:@"filter"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        parsedStatement =   [self parseClassDefinition];
    } else if ( [next isEqual:@"system"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        STClassDefinition *schemeDef = [self parseClassDefinition];
        if ( !schemeDef.superclassName ) {
            schemeDef.superclassName=@"STSystem";
        }
        parsedStatement =   schemeDef;
    } else if ( [next isEqual:@"scheme"]) {
        //        NSLog(@"found a class definition");
        [self pushBack:next];
        STClassDefinition *schemeDef = [self parseClassDefinition];
        if ( !schemeDef.superclassName ) {
            schemeDef.superclassName=@"MPWScheme";
        }
        parsedStatement =   schemeDef;
    } else {
        [self pushBack:next];
        parsedStatement =  [self parseExpression];
    }
    LEAVE1(parsedStatement);
    return parsedStatement;
}

-parseStatements
{
	id first;
	id next;
	id expression;
    ENTER;
	first = [self parseStatement];
	expression=first;
	next = [self nextToken];
	if ( next && ([next isEqual:@"."] || [first isKindOfClass:[NSArray class]]) ) {
        TRACE(@"next statement top of loop",next);
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
    LEAVE1(expression);
	return expression;
}

-compile:aString
{
    ENTER;
    id expr;
/*
	[self setScanner:[STScanner scannerWithData:[aString asData]]];
	while ( token=[self nextToken] ) {
		[tokenArray addObject:token];
	}
	NSLog(@"tokens: %@",tokenArray);
*/
    [self resetSmbolTable];
    [self setScanner:[STScanner scannerWithData:[aString asData]]];
    expr = [self parseStatements];
//    NSLog(@"expr = %@",expr);
    LEAVE1(expr);
    return expr;
}

-(STScriptedMethod*)parseMethodDefinition:aString
{
    [self setScanner:[STScanner scannerWithData:[aString asData]]];
    return [self parseMethodDefinition];
}

-(STScriptedMethod*)parseMethodBodyWithHeader:(MPWMethodHeader*)header
{
    STScriptedMethod *method=[[STScriptedMethod new] autorelease];
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

-(STScriptedMethod*)parseMethodDefinition
{
    STScriptedMethod *method=nil;
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

-(STClassDefinition*)parseClassDefinitionFromString:aString
{
    [self setScanner:[STScanner scannerWithData:[aString asData]]];
    return [self parseClassDefinition];
}

-(MPWInstanceVariableDefinition *)parseVariableDefinition:(Class)variableDefClass
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
        STTypeDescriptor *type=[STTypeDescriptor descriptorForSTTypeName:typeName];

        NSString *possibleInitializationToken = [self nextToken];
        STVariableDefinition *def = [[[variableDefClass alloc] initWithName:name type:type] autorelease];
        if ( [possibleInitializationToken isEqual:@"←"] || [possibleInitializationToken isEqual:@":="] ) {
            def.initializer = [self parseExpression];
        } else {
            [self pushBack:possibleInitializationToken];
        }
        return def;
    } else {
        PARSEERROR(@"var expected in instance variable definition", next);
        return nil;
    }
}

-(MPWInstanceVariableDefinition *)parseInstanceVariableDefinition
{
    return [self parseVariableDefinition:[MPWInstanceVariableDefinition class]];
}

-(MPWVariableDefinition*)parseLocalVariableDefinition
{
    return [self parseVariableDefinition:[STVariableDefinition class]];
}

-(STPropertyPathDefinition *)parsePropertyPathDefinition
{
    NSString *nextToken  = [self nextToken];
    NSString *pathDef = @"";
    STPropertyPathDefinition *propertyDef=[[STPropertyPathDefinition new] autorelease];
    if ( ![nextToken isEqualToString:@"{"]) {
        [self pushBack:nextToken];
        STIdentifierExpression *pathExpression=[self makeComplexIdentifier:@"dummy:"];
        pathDef=[pathExpression name];
        nextToken  = [self nextToken];
    } else {
        
    }
    MPWGenericIdentifier *ref=[[[MPWGenericIdentifier alloc] initWithPath:pathDef] autorelease];
    MPWReferenceTemplate *path=[[[MPWReferenceTemplate alloc] initWithReference:ref] autorelease];
    propertyDef.propertyPath=path;
//    NSLog(@"nextToken after parse of property header: %@",nextToken);
    if ( [nextToken isEqualToString:@"{"]) {
//        NSLog(@"parse get/set method body");
        nextToken=[self nextToken];
//        NSLog(@"get/set:  %@",nextToken);
        while ( [nextToken isEqualToString:@"|="] || [nextToken isEqualToString:@"=|"]
               || [nextToken isEqualToString:@"=|="] || [nextToken isEqualToString:@"get"] || [nextToken isEqualToString:@"put"]|| [nextToken isEqualToString:@"post"]) {
            NSString *getOrSet=nextToken;
            MPWRESTVerb verb=MPWRESTVerbGET;
            if ( [getOrSet isEqual:@"put"] || [getOrSet isEqual:@"=|"] ) {
                verb=MPWRESTVerbPUT;
            } else  if ( [getOrSet isEqual:@"post"] || [getOrSet isEqual:@"+="] ) {
                verb=MPWRESTVerbPOST;
            }
            STPropertyMethodHeader *header=[[[STPropertyMethodHeader alloc] initWithTemplate:path verb:verb] autorelease];
            
            
            STScriptedMethod* body=[self parseMethodBodyWithHeader:header];
//            NSLog(@"did parse body: %@",body);
            nextToken=[self nextToken];
            
            if ( [getOrSet isEqualToString:@"|="] || [getOrSet isEqualToString:@"get"] ) {
                [propertyDef setMethod:body forVerb:MPWRESTVerbGET];
//                propertyDef.get=body;
            } else if ( [getOrSet isEqualToString:@"=|"] || [getOrSet isEqualToString:@"put"] ) {
                [propertyDef setMethod:body forVerb:MPWRESTVerbPUT];
                //                propertyDef.set=body;
            } else if ( [getOrSet isEqualToString:@"post"] ) {
                [propertyDef setMethod:body forVerb:MPWRESTVerbPOST];
                //                propertyDef.set=body;
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


-(STClassDefinition*)parseClassDefinition
{
    NSString *s=[self nextToken];
    Class defClass=nil;
    if ( [s isEqualToString:@"class"] || [s isEqualToString:@"extension"]) {
        defClass=[STClassDefinition class];
    } else  if ( [s isEqualToString:@"scheme"]) {
        defClass=[STClassDefinition class];
    } else  if ( [s isEqualToString:@"system"]) {
        defClass=[STClassDefinition class];
    } else  if ( [s isEqualToString:@"filter"]) {
        defClass=[STFilterDefinition class];
    }
    STClassDefinition *classDef=[[defClass new] autorelease];
    if ( classDef ) {
        NSString *name=[self nextToken];
        classDef.name = name;
        NSString *separator=[self nextToken];
        if ( [separator isEqualToString:@":"]) {
            NSString *superclassName=[self nextToken];
            if ( [superclassName isEqual:@"#"]) {
//                NSLog(@"== template class def ===");
//              [self pushBack:superclassName];
//                NSLog(@"parse the literal ");
                id result=[self parseLiteral];
//                NSLog(@"class with literal dict: %@",result);
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
                    STScriptedMethod *method=[self parseMethodDefinition];
                    [methods addObject:method];
                } else if ( [next isEqualToString:@"+"]) {
                    [self pushBack:next];
                    STScriptedMethod *method=[self parseMethodDefinition];
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
//                    NSLog(@"start of property path def: %@",[self scanner]);
                    STPropertyPathDefinition *prop=[self parsePropertyPathDefinition];
                    [propertyDefinitions addObject:prop];
                    next=[self nextToken];
                    [self pushBack:next];
//                    NSLog(@"nextToken after property parse of %@: %@",[[prop propertyPath] name],next);
                } else if ( [next isEqualToString:@"|{"]) {
                    MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:@"<void>writeObject:object sender:aSender"];
                    [self pushBack:@"{"];
                    STScriptedMethod *filterMethod=[self parseMethodBodyWithHeader:header];
                    //            NSLog(@"parsed: %@",filterMethod);
                    [methods addObject:filterMethod];
                    classDef.methods=methods;
                    //            NSLog(@"methods: %@",methods);
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
            STScriptedMethod *filterMethod=[self parseMethodBodyWithHeader:header];
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

-(STProtocolDefinition*)parseProtocolDefinitionWithClass:(Class)defClass
{
    STProtocolDefinition *protoDef=[[defClass new] autorelease];
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
            STScriptedMethod *filterMethod=[self parseMethodBodyWithHeader:header];
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

-(MPWReference*)bindingForIdentifier:(STIdentifier*)anIdentifier
{
	return [[self schemeForName:[anIdentifier schemeName]] bindingWithIdentifier:anIdentifier withContext:self];
}

-(MPWReference*)bindingForString:(NSString*)fullPath
{
    STIdentifier *identifier=nil;
	NSArray *parts=[fullPath componentsSeparatedByString:@":"];
	NSString *schemeName = @"default";
	NSString *path=fullPath;
	if ( [parts count] >= 2 ) {
		schemeName = [parts objectAtIndex:0];
        path=[path substringFromIndex:[schemeName length]+1];
	}
    identifier=[STIdentifier identifierWithName:path];

    [identifier setSchemeName:schemeName];
	return [self bindingForIdentifier:identifier];
}

-(void)defineMethodsForClassDefinition:(STClassDefinition*)classDefinition
{
    self.classes[classDefinition.name]=classDefinition;
    MPWClassMethodStore* store= [self classStoreForName:classDefinition.name];
    for ( STScriptedMethod *method in [classDefinition allMethods]) {
        [store installMethod:method];
    }
    if ( classDefinition.classMethods.count) {
        for ( STScriptedMethod *method in [classDefinition classMethods]) {
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
    [methodStore release];
    [connectorMap release];
    [_classes release];
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
    STIdentifierExpression *expr=[compiler compile:@"doc:."];
    EXPECTTRUE([expr isKindOfClass:[STIdentifierExpression class]], @"var:. parses to identifier expression");
    STIdentifier *identifier=[expr identifier];
    IDEXPECT([identifier schemeName], @"doc", @"scheme");
    IDEXPECT([identifier identifierName], @".", @"path");
}

+(void)testParsingMethodBodyPreservesSource
{
    STCompiler *compiler=[self compiler];
    [compiler evaluateScriptString:@"class  MPWMethodSourceCompilerTestClass1 : NSObject { -answer { 42. } }. "];
    STScriptedMethod *method=[[compiler methodStore] methodForClass:@"MPWMethodSourceCompilerTestClass1" name:@"answer"];
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


+(void)testDictLiteralKeysDoNotRequireHash
{
    IDEXPECT( [self evaluate:@"#{ a: 12 } at:'a'."], @(12), @"");
}

+(void)testParseSimpleLiteralDictWithSimplifiedStringKey
{
    NSDictionary *result=[[self compiler] evaluateScriptString:@"#{ #a: 3 }"];
    INTEXPECT(result.count, 1, @"one element");
    IDEXPECT( result[@"a"], @(3), @"contents");
}

+(void)testBasicConnectionExpressionIsParsed
{
    NSString *prepForTestProgram =@"source ← #MPWFixedValueSource{}";
    NSString *testProgram =@"source → stdout";
    STCompiler *compiler=[self compiler];
    [compiler evaluateScriptString:prepForTestProgram];
    id compiled = [compiler compile:testProgram];
    EXPECTTRUE([compiled isKindOfClass:[STConnectionDefiner class]], @"connector expr. should be top level");
}

+(void)testParsingConnectedObjectLiterals
{
    // same as BasicConnectionExpression, but without the temporary
    NSString *testProgram =@"#MPWFixedValueSource{  } -> stdout";

    STCompiler *compiler=[self compiler];
    id compiled = [compiler compile:testProgram];
    EXPECTTRUE([compiled isKindOfClass:[STConnectionDefiner class]], @"connector expr. should be top level");
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
    STClassDefinition* classDef=[[self compiler] compile:script];
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

+(void)testOctalLiteral
{
    IDEXPECT( [self evaluate:@"0o1"], @(1), @"octal constant");
    IDEXPECT( [self evaluate:@"0o10"], @(8), @"octal constant");
}

+(void)testBinaryLiteral
{
    IDEXPECT( [self evaluate:@"0b1001"], @(9), @"binary constant");
    IDEXPECT( [self evaluate:@"0b1111"], @(15), @"binary constant");
}

+(void)testCommentToEndOfLine
{
    IDEXPECT( [self evaluate:@"3. // 4"], @(3), @"to end of line");
    IDEXPECT( [self evaluate:@"3. // 5 \n 4."], @(4), @"after new line");
}

+(void)testUnclosedDictionaryLiteralThrowsCompilerException
{
    STCompiler *compiler = [self compiler];
    NSString *incompleteDictLiteral=@" #{ a: 2, b: 3  ";
    BOOL didThrow=NO;
    @try {
        [compiler compile:incompleteDictLiteral];
    } @catch (id e) {
        didThrow=YES;
    }
    EXPECTTRUE(didThrow, @"should have thrown a parse exception");
}

+(void)testParseNestedDictionaries
{
    STCompiler *compiler = [self compiler];
    NSString *nestedDict=@" #{ a: 2, b: #{  c: 12 } } ";
    
    // HACK:  turn the closingBraceLiteralDictHack off just for this, in order to
    //        see what the differences are with and without the hack
    
    compiler.closingBraceLiteralDictHack = false;
    compiler.trace = false;
    BOOL didThrow=NO;
    @try {
        [compiler compile:nestedDict];
    } @catch (id e) {
        didThrow=YES;
    }
    EXPECTFALSE(didThrow, @"threw a parse exception");
}


+(void)testParseEmptyDictionary
{
    STCompiler *compiler = [self compiler];
    NSString *emptyDict=@" #{ } ";
        
    compiler.closingBraceLiteralDictHack = false;
    compiler.trace = false;
    id parseResult=nil;
    id dictResult=nil;
    BOOL didThrow=NO;
    @try {
        parseResult = [compiler compile:emptyDict];
    } @catch (id e) {
        didThrow=YES;
    }
    EXPECTFALSE(didThrow, @"threw a parse exception");
    IDEXPECT( [parseResult className],@"MPWLiteralDictionaryExpression",@"parsed");
    dictResult=[compiler evaluate:parseResult];
    IDEXPECT( dictResult, @{} ,@"evaluated");
}


+(void)testParseEmptyLiteralDictAsReceiver
{
    STCompiler *compiler = [self compiler];
    NSString *dictReceiver=@" #{ } at:'a'";
    
    compiler.closingBraceLiteralDictHack = false;  // this used to only work with the hack, but is fixed now
    id parseResult=nil;
    BOOL didThrow=NO;
    @try {
        parseResult = [compiler compile:dictReceiver];
    } @catch (id e) {
        didThrow=YES;
    }
    EXPECTFALSE(didThrow, @"threw a parse exception");
    IDEXPECT( [parseResult className],@"MPWMessageExpression",@"parsed");
}


+(void)testTryingToUseRoundBracketsForReturnTypeRaises
{
    STCompiler *compiler = [self compiler];
    NSString *roundBrackets=@"class hi { -(void)there { 32. } }";
    BOOL didRaise;
    @try {
        STClassDefinition *def = [compiler compile:roundBrackets];
        didRaise=NO;
    } @catch (id exception ) {
        didRaise=YES;
    }
    EXPECTTRUE(didRaise, @"did raise");
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
              @"testDictLiteralKeysDoNotRequireHash",
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
              @"testOctalLiteral",
              @"testHexLiteral",
              @"testBinaryLiteral",
              @"testCommentToEndOfLine",
              @"testUnclosedDictionaryLiteralThrowsCompilerException",
              @"testParseNestedDictionaries",
              @"testParseEmptyDictionary",
              @"testParseEmptyLiteralDictAsReceiver",
              @"testTryingToUseRoundBracketsForReturnTypeRaises",
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


@implementation NSObject(creatLotsOfObjectsToCheckForLeaks)

+(void)creatLotsOfObjectsToCheckForLeaks:(long)numberOfIteratons
{
    for (long i=0;i<numberOfIteratons;i++) {
        @autoreleasepool {
            [[self new] autorelease];
        }
    }
}

@end

