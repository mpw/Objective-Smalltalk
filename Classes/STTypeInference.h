//
//  STTypeInference.h
//  ObjectiveSmalltalk
//
//  Phase 1 of the type-system roadmap: a static type-inference skeleton.
//  Expressions can report their result type; a typing context holds the
//  types of in-scope names; a type provider answers "what does this
//  selector return on this type" (the information the runtime previously
//  gathered on the fly in MPWMessage).
//

#import <ObjectiveSmalltalk/STExpression.h>
#import <ObjectiveSmalltalk/MPWMessageExpression.h>

@class MPWTypeDefinition, STScriptedMethod;

NS_ASSUME_NONNULL_BEGIN

// Answers type questions about selectors that the runtime used to discover
// per-send.  Phase 1 ships the runtime-backed provider; later phases add
// hardcoded-table and header-file sources behind the same protocol.
@protocol STTypeProvider <NSObject>
-(nullable MPWTypeDefinition*)returnTypeForSelector:(SEL)selector receiverType:(nullable MPWTypeDefinition*)receiverType;
@end

// A symbol table of in-scope names → types, plus the type of `self`.
@interface STTypeContext : NSObject

@property (nonatomic, strong, nullable) MPWTypeDefinition *selfType;
@property (nonatomic, strong) id<STTypeProvider> typeProvider;

+(instancetype)context;
// Seeds argument types, local `var` definition types, and self (id unless set).
+(instancetype)contextForMethod:(STScriptedMethod*)method;

-(void)declareName:(NSString*)name type:(MPWTypeDefinition*)type;
-(nullable MPWTypeDefinition*)typeForName:(NSString*)name;
-(MPWTypeDefinition*)idType;

@end

// Runtime-backed type provider: introspects the statically-known class via
// -instanceMethodSignatureForSelector:.
@interface STRuntimeTypeProvider : NSObject <STTypeProvider>
+(instancetype)provider;
@end

// Built-in knowledge of the core selectors whose result type is fixed or
// operand-driven rather than discoverable from a class: comparisons (→ bool),
// arithmetic on a primitive receiver (→ that primitive), and the common
// primitive extractors (intValue, length, …).
@interface STHardcodedTypeProvider : NSObject <STTypeProvider>
+(instancetype)provider;
@end

// Tries each provider in order, first non-nil answer wins.
@interface STCompositeTypeProvider : NSObject <STTypeProvider>
+(instancetype)providerWithProviders:(NSArray<id<STTypeProvider>>*)providers;
@end

@interface NSObject (typeInference)
// The static type of this expression's result.  Defaults to id; never nil.
-(MPWTypeDefinition*)resultTypeIn:(nullable STTypeContext*)context;
@end


// An explicit box (primitive → object) or unbox (object → primitive) inserted
// at a type boundary.  Backend-agnostic: the ObjC generator and native compiler
// lower it; the interpreter treats it as a pass-through (values are boxed there).
@interface STCoerce : STExpression
@property (nonatomic, strong) STExpression *expression;
@property (nonatomic, strong) MPWTypeDefinition *fromType;
@property (nonatomic, strong) MPWTypeDefinition *toType;

+(instancetype)coerce:(STExpression*)expression from:(MPWTypeDefinition*)fromType to:(MPWTypeDefinition*)toType;
// Returns expression wrapped in a coercion iff crossing the object/primitive
// boundary; otherwise returns expression unchanged.
+(STExpression*)coerceExpression:(STExpression*)expression to:(MPWTypeDefinition*)toType in:(nullable STTypeContext*)context;
// Coerces the value a method/block body (statement list or single expression)
// yields — its last non-definition statement — to toType.  Returns the body.
+(id)coerceResultOf:(id)body to:(MPWTypeDefinition*)toType in:(nullable STTypeContext*)context;

-(BOOL)isBoxing;      // primitive → object
-(BOOL)isUnboxing;    // object → primitive
@end


// A message send resolved to an early-bound primitive operation because its
// operands are primitive-typed (e.g. int + int).  It is a message send, so
// backends that don't special-case it fall back to the correct late-bound send;
// the ObjC generator / native compiler lower it to a C operator / instruction.
@interface STPrimitiveMessageExpression : MPWMessageExpression
@property (nonatomic, strong) MPWTypeDefinition *primitiveResultType;
+(instancetype)fromMessage:(MPWMessageExpression*)message resultType:(nullable MPWTypeDefinition*)resultType;
@end


@interface NSObject (typeAnnotation)
// Returns this node with early-bound bindings resolved and coercions inserted.
// May return a different node; callers must use the return value.
-(id)typeAnnotateIn:(nullable STTypeContext*)context;
@end


// Permissive static typechecker.  It reports a message send only when the
// receiver's static type is a known class that does not respond to the
// selector — the same target-port compatibility the connector protocol embodies
// (STMessageConnector's isCompatible).  id / unknown / primitive receivers pass,
// so existing dynamically-typed code is never flagged.
@interface STTypeChecker : NSObject
+(NSArray<NSString*>*)diagnosticsFor:(id)node in:(nullable STTypeContext*)context;
@end

@interface NSObject (typeChecking)
-(void)typeCheckIn:(nullable STTypeContext*)context diagnostics:(NSMutableArray<NSString*>*)diagnostics;
@end

NS_ASSUME_NONNULL_END
