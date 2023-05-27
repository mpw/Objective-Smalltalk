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
    char *script =
    "import re\n"
    "import sys\n"
    "sys.path.append('/opt/homebrew/lib/python3.9/site-packages')\n"
    "from yt_dlp import _real_main\n"
    "args = [  'https://www.youtube.com/watch?v=XqUgUgiToNs' ]\n"
    "print('Before exexuting')\n"
    "_real_main(args)\n"
    "print('After exexuting')\n";
//    NSLog(@"script:\n%s",script);
    PyRun_SimpleString(script);
}

//     "main()\n"


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
