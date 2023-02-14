//
//  MPWSelfContainedBindingsScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWSelfContainedBindingsScheme.h"
#import "STEvaluator.h"
#import <objc/runtime.h>

@implementation MPWSelfContainedBindingsScheme


-evaluateIdentifier:anIdentifier withContext:aContext
{
    static id nilClass = nil;
    if (!nilClass) {
        nilClass=[NSNil class];
    }
//    NSLog(@"%@ evaluateIdentifier:%@ withContext: %@",[self className],anIdentifier,aContext);
    id value = [super evaluateIdentifier:anIdentifier withContext:aContext];
//    NSLog(@"value: %@",value);
    if ( !value ) {
        id binding=[self bindingWithIdentifier:anIdentifier withContext:aContext];
//        NSLog(@"fallback binding: %@",binding);
       if (!binding) {
//           NSLog(@"fetch value via undefinedVariableNamed:");
            value=[aContext valueForUndefinedVariableNamed:[anIdentifier path]];
        } else {
            value=[binding value];
//            NSLog(@"fallback binding value: %@",value);
        }
    }
    if ( object_getClass( value) == nilClass ) {
        value=nil;
    }
    return value;
}

@end
