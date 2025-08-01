/* MPWMessageExpression.h created by marcel on Tue 04-Jul-2000 */

#import <ObjectiveSmalltalk/STExpression.h>

@interface MPWMessageExpression : STExpression
{
    STExpression*      receiver;
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
-(instancetype)initWithReceiver:(STExpression*)newReceiver;

-(NSString*)messageName;
-(NSString*)messageNameForCompletion;

@property (nonatomic, assign) BOOL isSuperSend;
@property (nonatomic, strong) NSString* nonMappedMessageName;


@end
