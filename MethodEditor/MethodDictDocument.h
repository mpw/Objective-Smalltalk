//
//  MethodDict.h
//  MethodEditor
//
//  Created by Marcel Weiher on 9/25/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MPWFoundation/MPWFoundation.h>

@class MPWStCompiler;

#import "SimpleMethodDictDocument.h"

@interface MethodDictDocument : SimpleMethodDictDocument
{
    MPWStCompiler *interpreter;
    MPWStCompiler *syntaxCheckCompiler;
    NSString *baseURL;
}


objectAccessor_h(MPWStCompiler , interpter, setInterpreter)


@end
