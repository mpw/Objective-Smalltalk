//
//  MPWGlobalVariableStore.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 22.01.21.
//

#import "MPWGlobalVariableStore.h"
#include <dlfcn.h>

#ifndef RTLD_DEFAULT
#define RTLD_DEFAULT 0
#endif

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

@implementation MPWGlobalVariableStore(testing)

id MPWGlobalVariableStore_test_global=@"global variable test content";

+(void)testCanReadGlboal
{
    MPWGlobalVariableStore *globals=[MPWGlobalVariableStore store];
    IDEXPECT( globals[@"MPWGlobalVariableStore_test_global"], @"global variable test content",@"the global" );
    
}

+testSelectors
{
    return @[
        @"testCanReadGlboal",
    ];
}

@end
