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
    STPythonObject *obj=nil;
    NSArray *components=[aReference relativePathComponents];
    if ( [components[0] isEqual:@"module"]) {
        obj=[self import:components[1]];
        for (long i=2,max=components.count;i<max;i++) {
            obj=[obj at:components[i]];
        }
    } else {
        obj=[self import:@"__main__"];
        for (long i=0,max=components.count;i<max;i++) {
            obj=[obj at:components[i]];
        }

    }
    return obj;
}


-(STPythonObject*)import:(NSString*)module
{
    return [[[STPythonObject alloc] initWithPyObject:PyImport_Import( PyUnicode_FromString([module UTF8String]))] autorelease];
}

-(void)runString:(NSString*)pythonCode
{
    PyRun_SimpleString([pythonCode UTF8String]);
}

-(void)download:(NSString*)urlstring
{
    [[self import:@"sys"][@"path"][@"append"] call:@"/opt/homebrew/lib/python3.9/site-packages"];
    [[self import:@"yt_dlp"][@"_real_main"] call:@[ urlstring ]];
}

-(void)runBuiltinPythonScript:(NSString*)name
{
    [self runString:[[self frameworkResource:name category:@"py"] stringValue]];
}

-(void)runConstantServingWebDAV
{
    [self runBuiltinPythonScript:@"constant-webdav"];
}

-(void)loadSchemeWebDAV
{
    [self runBuiltinPythonScript:@"env-scheme-webdav"];
}

-mainModule
{
    PyObject* main_module = PyImport_AddModule("__main__");
    return [STPythonObject pyObject:main_module];
}


-(void)runSchemeWebDAV
{
    [self loadSchemeWebDAV];
    [[self mainModule][@"runServer"] call:nil];
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
