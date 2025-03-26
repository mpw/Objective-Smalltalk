//
//  STSimpleDataflowConstraint.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 18.04.21.
//

#import "STSimpleDataflowConstraint.h"

@implementation STSimpleDataflowConstraint

CONVENIENCEANDINIT( constraint, WithSource:source target:target)
{
    self=[super init];
    self.source=source;
    self.target=target;
    return self;
}

-(void)writeObject:(MPWRESTOperation*)op
{
    MPWIdentifier *ref=op.identifier;
    [self refDidChange:ref];
}

-(void)refDidChange:(id <MPWIdentifying>)aRef
{
    if ( [self.source isAffectedBy:aRef]) {
        [self update];
    }
}

-(void)update
{
    self.target.value = self.source.value;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation STSimpleDataflowConstraint(testing) 

+(void)testCanUpdate
{
    MPWDictStore *store=[MPWDictStore store];
    store[@"a"]=@42;
    store[@"b"]=@0;
    STSimpleDataflowConstraint *c=[STSimpleDataflowConstraint constraintWithSource:[store bindingForName:@"a" inContext:nil] target:[store bindingForName:@"b" inContext:nil]];
    [c update];
    IDEXPECT( store[@"b"], @42, @"did update");
}

+(void)testUpdateIfRefChanged
{
    MPWDictStore *store=[MPWDictStore store];
    store[@"a"]=@42;
    store[@"b"]=@0;
    STSimpleDataflowConstraint *c=[STSimpleDataflowConstraint constraintWithSource:[store bindingForName:@"a" inContext:nil] target:[store bindingForName:@"b" inContext:nil]];
    [c refDidChange:@"c"];
    IDEXPECT(store[@"b"],@0, @"shouldn't change when non-involved variable changes");
    [c refDidChange:@"b"];
    IDEXPECT(store[@"b"],@0, @"shouldn't change when target changes");
    [c refDidChange:@"a"];
    IDEXPECT(store[@"b"],@42, @"should change when source changes");
}

+(void)testCanListenToLoggingStore
{
    MPWDictStore *store=[MPWDictStore store];
    MPWLoggingStore *l=[MPWLoggingStore storeWithSource:store];
    store[@"a"]=@42;
    store[@"b"]=@0;
    STSimpleDataflowConstraint *c=[STSimpleDataflowConstraint constraintWithSource:[store bindingForName:@"a" inContext:nil] target:[store bindingForName:@"b" inContext:nil]];
    l.log = c;
    l[@"a"]=@20;
    IDEXPECT(store[@"b"],@20, @"writes via logging store are tracked");
}



+(NSArray*)testSelectors
{
   return @[
       @"testCanUpdate",
       @"testUpdateIfRefChanged",
       @"testCanListenToLoggingStore",
			];
}

@end
