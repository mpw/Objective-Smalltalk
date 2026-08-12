//
//  MPWLanguageGenerator.h
//  ObjectiveSmalltalk
//
//  Abstract base for the Objective-Smalltalk source generators.
//

#import <MPWFoundation/MPWFoundation.h>

/// Abstract base for the language backends that transpile the Objective-Smalltalk
/// AST to source text (MPWObjCGenerator → Objective-C, MPWJavaScriptGenerator →
/// Cappuccino Objective-J).  It fixes the code-generation contract every backend
/// shares:
///   * the target is a mutable string (see +defaultTarget),
///   * traversal is double-dispatch — -writeObject: (inherited from MPWByteStream)
///     sends -streamWriterMessage to each AST node, and per-language categories on
///     the node classes implement that selector to emit their syntax,
///   * +transpile: compiles source and streams the resulting AST through a fresh
///     generator, returning the generated text.
///
/// Subclasses MUST override -streamWriterMessage to return their own dispatch
/// selector.  Everything language-specific — the node categories, type handling,
/// lowering — lives in the subclass; this base only owns what is identical across
/// backends.
@interface MPWLanguageGenerator : MPWByteStream

/// Compile Objective-Smalltalk source and return the generated target-language text.
+(NSString*)transpile:(NSString*)source;

@end
