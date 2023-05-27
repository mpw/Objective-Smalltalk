//
//  STYtb_dlp.m
//  PyObjS
//
//  Created by Marcel Weiher on 27.05.23.
//

#import "STPython.h"
#import <Python/Python.h>
#import "STPythonObject.h"



@implementation STPython
{
}

-(instancetype)init
{
    self=[super init];
    Py_Initialize();
    return self;
}

-(id)at:(id<MPWReferencing>)aReference
{
    NSArray *components=[aReference relativePathComponents];
    if ( [components[0] isEqual:@"module"]) {
        STPythonObject *obj=[self import:components[1]];
        for (long i=2,max=components.count;i<max;i++) {
            obj=[obj at:components[i]];
        }
        return obj;
    }
    return nil;
}


-(STPythonObject*)import:(NSString*)module
{
    return [[[STPythonObject alloc] initWithPyObject:PyImport_Import( PyUnicode_FromString([module UTF8String]))] autorelease];
}


-(void)download:(NSString*)urlstring
{
    [[self import:@"sys"][@"path"][@"append"] call:@"/opt/homebrew/lib/python3.9/site-packages"];
    [[self import:@"yt_dlp"][@"_real_main"] call:@[ urlstring ]];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STPython(testing) 

+(void)someTest
{
    STPython *py=[[STPython new] autorelease];
//    [py run];
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
