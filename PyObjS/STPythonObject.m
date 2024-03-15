//
//  STPythonObject.m
//  PyObjS
//
//  Created by Marcel Weiher on 27.05.23.
//

#import "STPythonObject.h"
#import <Python/Python.h>

@implementation STPythonObject
{
    PyObject *pyObject;
}

+(instancetype)pyString:(NSString*)s;
{
    return [self pyObject:PyUnicode_FromString([s UTF8String])];
}

+(instancetype)pyObject:(void*)pyObjectIn
{
    return [[[self alloc] initWithPyObject:pyObjectIn] autorelease];
}

-(instancetype)pyObject:(void*)pyObjectIn
{
    return [[self class] pyObject:pyObjectIn];
}

-(instancetype)initWithPyObject:(void*)pyObjectIn
{
    if ( (self=[super init]) && pyObjectIn) {
        pyObject = pyObjectIn;
    } else {
        [self release];
        return nil;
    }
    return self;
}

-(instancetype)at:(NSString*)s
{
    return [self pyObject:PyObject_GetAttrString(pyObject, [s UTF8String])];
}

-(void*)pythonObject
{
    return pyObject;
}

-(instancetype)call:arg
{
    PyObject *pyResult = PyObject_CallFunctionObjArgs( pyObject, [[arg asPythonObject] pythonObject], NULL);
    return [self pyObject:pyResult];
}

-objectForKeyedSubscript:key
{
    return [self at:key];
}

-(id)asObject
{
    if ( PyNumber_Check(pyObject)) {
        return @(PyNumber_AsSsize_t(pyObject, NULL));
    } else if ( PyByteArray_Check( pyObject )) {
        return @(PyByteArray_AsString(pyObject));
    } else if ( PyUnicode_Check( pyObject )) {
        const char *utf8;
        Py_ssize_t size;
        
        utf8=PyUnicode_AsUTF8AndSize(pyObject, &size);
        return [NSString stringWithUTF8String:utf8];
    } else {
        NSLog(@"other kind of object ");
        PyObject *s=PyObject_Repr(pyObject);
        return [[[self class] pyObject:s] asObject];
    }
    return nil;
}

@end


@implementation NSObject(asPyObject)

-asPythonObject {   [NSException raise:@"unsupported" format:@"object of class %@ cannot be converted to Python",[self className]]; return nil; }

@end

@implementation NSString(asPyObject)

-asPythonObject {   return [STPythonObject pyString:self]; }

@end

@implementation NSArray(asPyObject)

-asPythonObject {
    PyObject *list=PyList_New(self.count);
    
    for (long i=0,max=self.count;i<max;i++) {
        PyList_SetItem( list , i,  [[self[i] asPythonObject] pythonObject]);
    }
    return [STPythonObject pyObject:list];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation STPythonObject(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
