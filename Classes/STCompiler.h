/* STCompiler.h created by marcel on Mon 03-Jul-2000 */

#import <ObjectiveSmalltalk/STEvaluator.h>

@class MPWMethodHeader,STScanner,MPWMethodStore,STScriptedMethod,STClassDefinition;

@interface STCompiler : STEvaluator
{
    STScanner *scanner;
    id tokens;
	MPWMethodStore* methodStore;
    NSMutableDictionary *symbolTable;
	id connectorMap;
    id solver;
}

+compiler;
+evaluate:aString;
-evaluateScriptString:aString;
-(STScriptedMethod*)parseMethodDefinition:aString;
-(STClassDefinition*)parseClassDefinitionFromString:aString;

-compile:aString;
-(id)compileAndEvaluate:(NSString*)aString;
-nextToken;
-(void)pushBack:aToken;

-parseMessageExpression:receiver;

//  defining methods, getting defined methods
-(void)defineConnectorClass:(Class)aClass forConnectorSymbol:(NSString*)symbol;

-parseStatements;
-parseExpression;
-mapConnector:aConnectorExpression;
-(MPWReference*)bindingForString:(NSString*)fullPath;
-(BOOL)isValidSyntax:(NSString*)stString;

//---- method store 

-(MPWMethodStore*)methodStore;
-(void)addScript:scriptString forClass:className methodHeaderString:methodHeaderString;
-(void)addScript:scriptString forMetaClass:className methodHeaderString:methodHeaderString;
-(NSArray*)classesWithScripts;
-(NSArray*)methodNamesForClassName:(NSString*)className;
-(NSDictionary*)externalScriptDict;
-(void)defineMethodsInExternalDict:(NSDictionary*)scriptDict;
//-methodDictionaryForClassNamed:(NSString*)className;
-methodForClass:aClassName name:aMethodName;

idAccessor_h(solver, setSolver)

@property (readonly) NSMutableDictionary <NSString*,STClassDefinition*> *classes;

-(STClassDefinition*)classForName:(NSString*)className;

@end

