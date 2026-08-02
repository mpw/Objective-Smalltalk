#import <MPWFoundation/MPWFoundation.h>

/** Transpiles ObjectiveSmalltalk AST nodes to Cappuccino Objective-J runtime JavaScript. */
@interface MPWJavaScriptGenerator : MPWByteStream

-(void)generateIdentifier:(id)identifier;
-(void)writeMessage:(NSString*)selector toReceiver:(id)receiver withArgs:(NSArray*)args superSend:(BOOL)isSuperSend;
-(void)writeStatements:(NSArray*)statements returningLast:(BOOL)returnLast;

/** Convenience entry point: parse source and return Cappuccino-compatible JavaScript. */
+(NSString*)transpile:(NSString*)source;

@end
