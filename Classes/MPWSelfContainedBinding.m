//
//  MPWSelfContainedBinding.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWSelfContainedBinding.h"
#import <MPWFoundation/MPWPathRelativeStore.h>

@interface MPWSelfContainedBinding()

@property (nonatomic, strong) id identifier;
@property (nonatomic, strong) id scheme;
@property (nonatomic, strong) id reference;         // FIXME:  compatibilty with MPWBinding
@property (nonatomic, assign) BOOL isObserving;
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

- (NSURL *)URL { 
    return nil;
}

-nextObject
{
    return self.value;
}

-(void)writeObject:anObject
{
    [self setValue:anObject];
}

+ (instancetype)referenceWithIdentifier:(id)aReference inStore:(id)aStore {
    return nil;
}


- (BOOL)hasChildren { 
    return NO;
}

- (NSArray *)children {
    return nil;
}

- (id)asScheme {
    return [self scheme];
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

//------------  DeltaBlue suppport


-(id)_objectToIndex:(int)anIndex
{
    return self.value;
}

-(NSString*)finalKey
{
    return [[self.identifier pathComponents] lastObject];
}

-(void)_setValue:newValue
{
    self.value=newValue;
}

-(void)startObserving
{
//        if (!self.isObserving) {
//                [[self _objectToIndex:-1] objst_addObserver:self forKey:[self finalKey]];
//                self.isObserving=YES;
//            }
//
    }

-(void)stopObserving
{
//        [[self _objectToIndex:-1] removeObserver:self forKeyPath:[self finalKey]];
//        self.isObserving=NO;
}



@end
