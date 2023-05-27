//
//  STYtb_dlp.m
//  PyObjS
//
//  Created by Marcel Weiher on 27.05.23.
//

#import "STYtb_dlp.h"
#import <Python/Python.h>





@implementation STYtb_dlp
{
}

-(instancetype)init
{
    self=[super init];
    Py_Initialize();
    return self;
}

-(void)run
{
    NSString *os=@"https://www.youtube.com/watch?v=XqUgUgiToNs";
    char *s=[os UTF8String];
    int len=strlen(s);
    char *script1 =
    "import re\n"
    "import sys\n"
    "sys.path.append('/opt/homebrew/lib/python3.9/site-packages')\n";

    PyRun_SimpleString(script1);

    PyObject *pyURL=PyUnicode_FromString(s );
    PyObject *moduleName=PyUnicode_FromString("yt_dlp" );
    PyObject *yt_dlp_module=PyImport_Import(moduleName);

    PyObject *mainFunction = PyObject_GetAttrString(yt_dlp_module, "_real_main");
    
    PyObject *args = PyList_New(1);
    PyList_SetItem(args, 0, pyURL);
    PyObject_CallFunctionObjArgs(mainFunction, args, NULL);
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STYtb_dlp(testing) 

+(void)someTest
{
    STYtb_dlp *py=[[STYtb_dlp new] autorelease];
//    [py run];
}

+(NSArray*)testSelectors
{
   return @[
			@"someTest",
			];
}

@end
