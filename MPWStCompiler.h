/* MPWStCompiler.h created by marcel on Mon 03-Jul-2000 */

#import <MPWTalk/MPWEvaluator.h>

@class MPWMethodHeader;

@interface MPWStCompiler : MPWEvaluator
{
    id scanner;
    id tokens;
	id methodStore;
	id connectorMap;
}

+evaluate:aString;
-evaluateScriptString:aString;

-compile:aString;
-nextToken;
-(void)pushBack:aToken;

-parseMessageExpression:receiver;

//  defining methods, getting defined methods
-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol;

-parseStatements;
-parseExpression;
-parseBlock;
-mapConnector:aConnectorExpression;

//---- method store 

-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString;
-(NSArray*)classesWithScripts;
-(NSArray*)methodNamesForClassName:(NSString*)className;
-(NSDictionary*)externalScriptDict;
-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict;
-methodDictionaryForClassNamed:(NSString*)className;
-methodForClass:aClassName name:aMethodName;


@end

