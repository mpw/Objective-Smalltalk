//
//  MPWCommandStore.m
//  StshFramework
//
//  Created by Marcel Weiher on 24.07.22.
//

#import "MPWCommandStore.h"
#import "MPWShellProcess.h"

@implementation MPWCommandStore

-(id)at:(id<MPWReferencing>)aReference
{
    NSArray *components = [aReference pathComponents];
    NSString *name=[components firstObject];
    NSArray *args = [components subarrayWithRange:NSMakeRange(1,components.count-1)];
    MPWShellProcess *process=[MPWShellProcess processWithName:name];
    [process setArguments:args];
    NSMutableData *result=[NSMutableData data];
    [process runWithTarget:[MPWByteStream streamWithTarget:result]];
    return result;
}


@end


@implementation MPWCommandStore(testing)



@end
