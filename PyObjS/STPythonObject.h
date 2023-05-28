//
//  STPythonObject.h
//  PyObjS
//
//  Created by Marcel Weiher on 27.05.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//typedef struct Object PyObject;

@interface STPythonObject : NSObject

+(instancetype)pyString:(NSString*)s;
+(instancetype)pyObject:(void*)pyObjectIn;
-(instancetype)initWithPyObject:(void*)pyObjectIn;
-(instancetype)at:(NSString*)s;
-(void*)pythonObject;
-(instancetype)call:arg;
-objectForKeyedSubscript:key;
-asObject;

@end

@interface NSObject(asPythonObject)
-(STPythonObject*)asPythonObject;
@end

NS_ASSUME_NONNULL_END
