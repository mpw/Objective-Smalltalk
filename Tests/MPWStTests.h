//
//  MPWStTests.h
//  Arch-S
//
//  Created by Marcel Weiher on 14/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STCompiler.h>


@interface MPWStTests : STCompiler {

}

@end

#define TESTEXPR( expr, expected )\
{\
   id result=nil;\
   id expectedString;\
   @try { \
      result = (STExpression*)[self evaluate:expr];\
      result = [result stringValue];\
      expectedString=[expected stringValue];\
   } @catch (NSException *e) {\
       NSAssert3( 0, @"evaluating '%@' and expecting '%@' raised %@",expr,expectedString,e);\
   }\
   IDEXPECT( result, expectedString , @"not equal");\
}\

