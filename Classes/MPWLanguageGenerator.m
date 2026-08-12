//
//  MPWLanguageGenerator.m
//  ObjectiveSmalltalk
//

#import "MPWLanguageGenerator.h"
#import "STCompiler.h"

@implementation MPWLanguageGenerator

// Not a test class itself — don't inherit MPWByteStream's tests, which assume its
// data target rather than our string target.
+testSelectors { return @[]; }

+defaultTarget
{
    return [NSMutableString string];
}

+(NSString*)transpile:(NSString*)source
{
    NSMutableString *result=[NSMutableString string];
    MPWLanguageGenerator *generator=[self streamWithTarget:result];
    [generator writeObject:[[STCompiler compiler] compile:source]];
    return result;
}

@end
