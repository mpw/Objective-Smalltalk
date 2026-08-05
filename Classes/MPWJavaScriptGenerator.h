#import <MPWFoundation/MPWFoundation.h>

/** Transpiles ObjectiveSmalltalk AST nodes to Cappuccino Objective-J source. */
@interface MPWJavaScriptGenerator : MPWByteStream

-(void)generateIdentifier:(id)identifier;
-(void)writeMessage:(NSString*)selector toReceiver:(id)receiver withArgs:(NSArray*)args superSend:(BOOL)isSuperSend;
-(void)writeStatements:(NSArray*)statements returningLast:(BOOL)returnLast;

/** Convenience entry point: parse source and return Cappuccino-compatible Objective-J. */
+(NSString*)transpile:(NSString*)source;
+(NSString*)transpileToObjectiveJ:(NSString*)source;

@end
