//
//  MPWPropertyPath.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import "MPWPropertyPath.h"
#import <MPWFoundation/MPWFoundation.h>
#import "MPWPropertyPathComponent.h"

@implementation MPWPropertyPath


CONVENIENCEANDINIT( propertyPath, WithReference:(id <MPWReferencing>)ref)
{
    self=[super init];
    NSMutableArray *comps=[NSMutableArray array];
    for ( NSString *s in ref.pathComponents) {
        [comps addObject:[MPWPropertyPathComponent componentWithString:s]];
    }
    self.pathComponents=comps;
    return self;
}

CONVENIENCEANDINIT( propertyPath, WithPathString:(NSString*)path)
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:path];

    return [self initWithReference:ref];
}


-(NSString*)name
{
    return [(NSArray*)[[self.pathComponents collect] pathName] componentsJoinedByString:@"/"];
}

-(NSDictionary*)bindingsForMatchedReference:(id <MPWReferencing>)ref;
{
    return nil;
}

-(void)dealloc
{
    [_pathComponents release];
    [super dealloc];
}


@end


@implementation MPWPropertyPath(testing)


+(void)testInitializeWithSingleConstantPath
{
    MPWPropertyPath *pp=[self propertyPathWithPathString:@"hello"];
    INTEXPECT([[pp pathComponents] count], 1, @"number of components")
    MPWPropertyPathComponent *pc=pp.pathComponents[0];
    IDEXPECT([pc name], @"hello", @"name");
    
}

+testSelectors
{
    return @[
        @"testInitializeWithSingleConstantPath",
    ];
}

@end

