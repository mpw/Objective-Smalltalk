#import <ObjectiveSmalltalk/MPWLanguageGenerator.h>

/** Transpiles ObjectiveSmalltalk AST nodes to Cappuccino Objective-J runtime JavaScript.
    +transpile: is inherited from MPWLanguageGenerator. */
@interface MPWJavaScriptGenerator : MPWLanguageGenerator

-(void)generateIdentifier:(id)identifier;
-(void)writeMessage:(NSString*)selector toReceiver:(id)receiver withArgs:(NSArray*)args superSend:(BOOL)isSuperSend;
-(void)writeStatements:(NSArray*)statements returningLast:(BOOL)returnLast;

@end
