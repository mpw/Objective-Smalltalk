//
//  MPWPropertyPathGetter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/26/18.
//

#import "MPWPropertyPathGetter.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWFoundation/MPWReferenceTemplate.h>
#import "MPWPropertyPathDefinition.h"
#import "MPWMethodHeader.h"

@interface MPWPropertyPathGetter()

@property (nonatomic, strong) MPWTemplateMatchingStore *store;

@end

@implementation MPWPropertyPathGetter

-(void)setupStoreWithPaths:(NSArray<MPWPropertyPathDefinition*>*)newPaths
{
    for ( MPWPropertyPathDefinition *def in newPaths) {
        if ( def.get ) {
            self.store[def.propertyPath] = def.get;
        }
    }
}


CONVENIENCEANDINIT(getter, WithPropertyPathDefinitions:newPaths)
{
    self=[super init];
    self.store = [MPWTemplateMatchingStore store];
    self.store.addRef = true;
    [self setupStoreWithPaths:newPaths];
    self.methodHeader=[MPWMethodHeader methodHeaderWithString:[self declarationString]];
    return self;
}

-(id)evaluateOnObject:(id)target parameters:(NSArray *)parameters
{
    id ref=[parameters.lastObject name];        // the lastObject is an MPWIdentifier
    self.store.target = target;                 // should pass as parameter not method
                                    
    return [self.store at:ref];         // this returns nil when there's no match, previous threw exception?
}

-declarationString
{
    return @"at:aReference";
}

-(void)setContext:(id)newVar
{
    [super setContext:newVar];
    [self.store setContext:newVar];
}

-(void)dealloc
{
    [_store release];
    [super dealloc];
}

-(NSString*)script
{
    return @" 'property path'. ";
}

-(BOOL)isPropertyPathDefs
{
    return YES;
}

@end
