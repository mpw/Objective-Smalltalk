//
//  MPWGlobalVariableStore.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 22.01.21.
//

#import "MPWGlobalVariableStore.h"
#include <dlfcn.h>

@implementation MPWGlobalVariableStore

-(id)at:(id<MPWReferencing>)aReference
{
    NSString *s=[aReference path];
    const char *symbol=[s UTF8String];
    id* ptr=dlsym( RTLD_DEFAULT, symbol );
    if ( ptr )  {
        return *ptr;
    } else {
        return nil;
    }

}

@end
