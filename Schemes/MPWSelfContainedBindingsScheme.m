//
//  MPWSelfContainedBindingsScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWSelfContainedBindingsScheme.h"
#import "MPWEvaluator.h"
#import <objc/runtime.h>

@implementation MPWSelfContainedBindingsScheme


-evaluateIdentifier:anIdentifier withContext:aContext
{
    static id nilClass = nil;
    if (!nilClass) {
        nilClass=[NSNil class];
    }
    id value = [super evaluateIdentifier:anIdentifier withContext:aContext];
    if ( !value ) {
        id binding=[self bindingWithIdentifier:anIdentifier withContext:aContext];
        if (!binding) {
            value=[aContext valueForUndefinedVariableNamed:[anIdentifier path]];
        } else {
            value=[binding value];
        }
    }
    if ( object_getClass( value) == nilClass ) {
        value=nil;
    }
    return value;
}

@end
