//
//  testclass_objc.m
//  ObjSTNative
//
//  Created by Marcel Weiher on 25.10.22.
//

#import <Foundation/Foundation.h>

@interface TestClass:NSObject {}
-(long)method;

@end
@implementation TestClass

-(long)method { return [self hash]+200; }

@end
