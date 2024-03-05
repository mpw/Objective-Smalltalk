//
//  STEntityList.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STEntityList.h"
#import "STEntity.h"

@interface STEntityList()

@property (nonatomic, strong) NSMutableDictionary *entries;
@property (nonatomic, assign) long maxId;
@property (nonatomic, strong) Class entityClass;
@property (nonatomic, strong) NSString *location;


@end

@implementation STEntityList

-(long)nextId
{
    return ++(self.maxId);
}

-(void)setInitialData:(NSMutableDictionary*)newEntries
{
    self.entries=newEntries;
    self.maxId = newEntries.count;
}

-entriesArray  {
    return self.entries.allValues;
}

-(void)at:(id<MPWReferencing>)aReference put:(id)theObject
{
    NSString *idString=[[aReference relativePathComponents] lastObject];
    self.entries[@(idString.intValue)]=theObject;
}

-redirectToList
{
    return [MPWBinding bindingWithReference:[MPWGenericReference referenceWithPath:self.location] inStore:self];
}

-at:(id<MPWReferencing>)aReference post:(NSDictionary*)data
{
    NSLog(@"POST at %@",aReference);
    NSArray *pathComponents=[aReference relativePathComponents];
    NSString *idString=pathComponents.lastObject;
    id theEntity = nil;
    long theId=0;
    if ( [idString isEqual:@"post"]) {
        theId = [self nextId];
        theEntity = [self.entityClass id: theId];
    } else {
        theId = [pathComponents[pathComponents.count-2] intValue];
        theEntity = self.entries[@(theId)];
        NSLog(@"editing object %@ id %ld",theEntity,theId);
    }
    for ( NSString *key in data.allKeys) {
        [theEntity setValue: [data objectForKey:key] forKey:key];
    }
    self.entries[@(theId)]=theEntity;
    return [self redirectToList];
}


-at:(id<MPWReferencing>)aReference
{
    if ( [aReference isRoot] || aReference.path.length==0) {
        return self.entriesArray;
    } else {
        NSArray *pathComponents=[aReference relativePathComponents];
        NSString *idString=pathComponents.lastObject;
        if ( [idString isEqual:@"new"]) {
            return @"";
        } else if ( [idString isEqual:@"delete"]) {
            idString=pathComponents[pathComponents.count-2];
            self.entries[@(idString.intValue)]=nil;
            return [self redirectToList];
        } else if ( [idString isEqual:@"edit"]) {
            idString=pathComponents[pathComponents.count-2];
            return self.entries[@(idString.intValue)];
        } else {
            return  self.entries[@(idString.intValue)];
        }
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STEntityList(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
