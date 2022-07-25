//
//  MPWCommandBinding.m
//  StshFramework
//
//  Created by Marcel Weiher on 25.07.22.
//

#import "MPWCommandBinding.h"
#import "MPWShellProcess.h"

@implementation MPWCommandBinding

-stream
{
    NSArray *components = [self.reference pathComponents];
    NSString *name=[components firstObject];
    NSArray *args = [components subarrayWithRange:NSMakeRange(1,components.count-1)];
    MPWShellProcess *process=[MPWShellProcess processWithName:name];
    [process setArguments:args];
    return [process wrappedAsMPWStream];
}

-(NSData*)value
{
    MPWStreamSource *s=[self stream];
    NSMutableData *result=[NSMutableData data];
    s.target = [MPWByteStream streamWithTarget:result];
    [s run];
    return result;

}
@end
