//
//  MPWSelfContainedBindingsScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWSelfContainedBindingsScheme.h"

@implementation MPWSelfContainedBindingsScheme


-evaluateIdentifier:anIdentifer withContext:aContext
{
    id value = [super evaluateIdentifier:anIdentifer withContext:aContext];
    if ( !value ) {
        id binding=[self bindingWithIdentifier:anIdentifer withContext:aContext];
        NSLog(@"evaluateIdentifier falling back: %@",self);
        if (!binding) {
            value=[aContext valueForUndefinedVariableNamed:[anIdentifer identifierName]];
        } else {
            value=[binding value];
        }
    }
    
    if ( [value respondsToSelector:@selector(isNotNil)]  && ![value isNotNil] ) {
        value=nil;
    }
    return value;
}

@end
