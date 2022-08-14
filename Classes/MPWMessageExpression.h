/* MPWMessageExpression.h created by marcel on Tue 04-Jul-2000 */

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWMessageExpression : MPWExpression
{
    MPWExpression*      receiver;
    SEL	                selector;
    NSArray*            args;
    const char*         _argtypes;
    char                returnType;
}

idAccessor_h( receiver, setReceiver )
scalarAccessor_h( SEL, selector, setSelector )
scalarAccessor_h( const char*, argtypes, setArgtypes )
scalarAccessor_h( char , returnType, setReturnType )

objectAccessor_h(NSArray*, args, setArgs )
-initWithReceiver:newReceiver;

-(NSString*)messageName;
-(NSString*)messageNameForCompletion;

@property (nonatomic, assign) BOOL isSuper;


@end
