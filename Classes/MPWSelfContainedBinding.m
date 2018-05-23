//
//  MPWSelfContainedBinding.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWSelfContainedBinding.h"

@interface MPWSelfContainedBinding()

@property (nonatomic, strong) id identifier;
@property (nonatomic, strong) id scheme;

@end


@implementation MPWSelfContainedBinding

+(instancetype)bindingWithValue:(id)aValue
{
    return [[[self alloc] initWithValue:aValue] autorelease];
}

-(instancetype)initWithValue:aValue
{
    self=[super init];
    self.value=aValue;
    return self;
}

- (void)delete {
    self.value = nil;
}


-(void)dealloc
{
    [_value release];
    [_identifier release];
    [super dealloc];
}

//  compatibility

-(BOOL)isBound
{
    return self.value != nil;
}

-(void)bindValue:newValue
{
    self.value = newValue;
}

-(void)setDefaultContext:aContext {}

-(NSString*)name
{
    return [[self.identifier pathComponents] componentsJoinedByString:@"/"];
}


@end
