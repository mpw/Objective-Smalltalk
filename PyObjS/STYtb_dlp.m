//
//  STYtb_dlp.m
//  PyObjS
//
//  Created by Marcel Weiher on 27.05.23.
//

#import "STYtb_dlp.h"
#import <Python/Python.h>
#import "STPythonObject.h"



@implementation STYtb_dlp
{
}

-(instancetype)init
{
    self=[super init];
    Py_Initialize();
    return self;
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
