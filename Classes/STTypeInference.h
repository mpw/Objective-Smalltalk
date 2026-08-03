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

@interface STExpression (typeInference)
// The static type of this expression's result.  Defaults to id; never nil.
-(MPWTypeDefinition*)resultTypeIn:(nullable STTypeContext*)context;
@end

NS_ASSUME_NONNULL_END
