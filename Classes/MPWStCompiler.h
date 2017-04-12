/* MPWStCompiler.h created by marcel on Mon 03-Jul-2000 */

#import <ObjectiveSmalltalk/MPWEvaluator.h>

@class MPWMethodHeader,MPWStScanner,MPWMethodStore,MPWScriptedMethod,MPWClassDefinition;

@interface MPWStCompiler : MPWEvaluator
{
    MPWStScanner *scanner;
    id tokens;
	MPWMethodStore* methodStore;
    NSMutableDictionary *symbolTable;
	id connectorMap;
    id solver;
}

+compiler;
+evaluate:aString;
-evaluateScriptString:aString;
-(MPWScriptedMethod*)parseMethodDefinition:aString;
-(MPWClassDefinition*)parseClassDefinition:aString;

-compile:aString;
-(id)compileAndEvaluate:(NSString*)aString;
-nextToken;
-(void)pushBack:aToken;

-parseMessageExpression:receiver;

//  defining methods, getting defined methods
-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol;

-parseStatements;
-parseExpression;
-parseBlock;
-mapConnector:aConnectorExpression;
-(MPWBinding*)bindingForString:(NSString*)fullPath;
-(BOOL)isValidSyntax:(NSString*)stString;

//---- method store 

-(MPWMethodStore*)methodStore;
-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString;
-(NSArray*)classesWithScripts;
-(NSArray*)methodNamesForClassName:(NSString*)className;
-(NSDictionary*)externalScriptDict;
-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict;
-methodDictionaryForClassNamed:(NSString*)className;
-methodForClass:aClassName name:aMethodName;

idAccessor_h(solver, setSolver)

@end

