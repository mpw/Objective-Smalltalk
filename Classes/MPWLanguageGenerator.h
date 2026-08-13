//
//  MPWLanguageGenerator.h
//  ObjectiveSmalltalk
//
//  Abstract base for the Objective-Smalltalk source generators.
//

#import <MPWFoundation/MPWFoundation.h>

@class MPWTypeDefinition, STTypeContext, STScriptedMethod, STClassDefinition;
@class STIdentifier, STVariableDefinition, STCoerce, STPrimitiveMessageExpression, MPWMessageExpression;

NS_ASSUME_NONNULL_BEGIN



@interface MPWLanguageGenerator : MPWByteStream

/// Compile Objective-Smalltalk source and return the generated target-language text.
+(NSString*)transpile:(NSString*)source;

#pragma mark - shared code-generation state

/// Instance variables (name → type) of the class currently being generated.
@property (nonatomic, assign, nullable) NSDictionary *currentIvarTypes;
/// Types of the names in scope for the method currently being generated.
@property (nonatomic, assign, nullable) STTypeContext *currentTypeContext;
/// YES while emitting the class (meta) methods, so a method header can pick + over -.
@property (nonatomic, assign) BOOL generatingClassMethod;

-(BOOL)isInstanceVariableName:(NSString*)name;
/// Map an Objective-C class name to the target dialect (identity for Objective-C;
/// Objective-J swaps NS* → CP*).  Applied to type names and superclasses.
-(NSString*)mapClassName:(NSString*)className;

#pragma mark - shared traversal skeleton (implemented here, do not override)

/// Emit a statement list, optionally returning the value of the last non-definition
/// statement.  Runs control-structure lowering for discarded-value statements.
-(void)writeStatements:(NSArray*)statements returningLast:(BOOL)returnLast;
/// Emit a bare statement list (not a method/block body): statements separated by
/// ";\n", not terminated, no return, no lowering.
-(void)writeStatementList:(NSArray*)statements;
/// A control-structure send (ifTrue:/whileTrue:/to:do:/do:) with block arms whose
/// value is discarded, and so is lowerable to native control flow.
-(BOOL)isLowerableControlStructure:statement;
-(void)writeControlStructure:(MPWMessageExpression*)message;

#pragma mark - emit primitives (override per language)

// Literals and identifiers
-(void)emitStringLiteral:(NSString*)string;
-(void)emitNumberLiteral:(NSNumber*)number;
-(void)emitBooleanLiteral:(BOOL)value;
-(void)emitNilLiteral;
-(NSString*)nullLiteral;                        // the value returned for "no value" (nil / null)
-(void)emitIdentifier:(STIdentifier*)identifier;
-(void)emitAssignmentToLHS:(id)lhs from:(id)rhs;
-(void)emitInterpolatedString:(id)stringLiteral;

// Messages
-(void)emitMessageSelector:(NSString*)selector receiver:(id)receiver args:(NSArray*)args super:(BOOL)isSuperSend;
-(void)emitPrimitiveMessage:(STPrimitiveMessageExpression*)message;   // default: falls back to a message send
-(void)emitCoerce:(STCoerce*)coercion;                                // default: passes the expression through

// Blocks and collection literals
-(void)emitBlockPrologueWithArguments:(NSArray*)arguments;
-(void)emitBlockEpilogue;
-(void)emitArrayLiteralOpen:(nullable NSString*)className;
-(void)emitArrayLiteralClose:(nullable NSString*)className;
-(void)emitDictionaryLiteralOpen:(nullable NSString*)className;
-(void)emitDictionaryLiteralClose:(nullable NSString*)className;
-(void)emitDictionaryEntryKey:(id)key value:(id)value;

// Definitions
-(void)emitVariableDefinition:(STVariableDefinition*)definition;
-(void)emitConnectionFrom:(id)lhs to:(id)rhs;
-(void)emitMethodPrologue:(STScriptedMethod*)method;
-(void)emitMethodEpilogue:(STScriptedMethod*)method;
-(void)emitClassDefinition:(STClassDefinition*)classDefinition;

// Control-flow lowering hooks (used by the shared writeConditional/While/For)
-(void)emitBooleanCondition:(id)condition;
-(NSString*)loopVariableDeclaration;            // "long " / "var "
-(void)emitLoopBound:(id)bound;
-(void)emitForeachStatement:(MPWMessageExpression*)doMessage;

@end

// The single shared tree-walk: every AST node implements this to drive its own
// traversal through the generator's emit primitives.
@interface NSObject(MPWCodeGenerating)
-(void)generateCodeOn:(MPWLanguageGenerator*)generator;
@end

NS_ASSUME_NONNULL_END
