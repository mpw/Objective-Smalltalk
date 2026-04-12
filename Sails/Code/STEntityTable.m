//
//  STEntityTable.m
//  Sails
//
//  Created by Marcel Weiher on 11.04.26.
//

#import "STEntityTable.h"
#import "STPathToTemplateNameMapper.h"

@interface STEntityTable ()

@property (nonatomic, strong) MPWObjectArrayTable *entries;
@property (nonatomic, assign) long maxId;
@property (nonatomic, strong) NSString *location;


@end

@implementation STEntityTable


-(id <MPWStorage>)templateNameMapper
{
    STPathToTemplateNameMapper* mapper = [STPathToTemplateNameMapper store];
    mapper.baseName = [[self.entries itemClass] className];
    return mapper;
}

-(void)setInitialData:(MPWObjectArrayTable*)newTable
{
    NSLog(@"initial data: %@",newTable);
    self.entries=newTable;
}

-entriesArray  {
    return self.entries.objects;
}

-(void)at:(id<MPWIdentifying>)aReference put:(id)theObject
{
    NSString *idString=[[aReference relativePathComponents] lastObject];
    self.entries[idString.intValue]=theObject;
}

-redirectToList
{
    return [MPWReference referenceWithIdentifier:[MPWGenericIdentifier referenceWithPath:self.location] inStore:self];
}

-at:(id<MPWIdentifying>)aReference post:(NSDictionary*)data
{
    NSLog(@"POST at %@",aReference);
    NSArray *pathComponents=[aReference relativePathComponents];
    NSString *idString=pathComponents.lastObject;
    id theEntity = nil;
    long theId=0;
    if ( [idString isEqual:@"post"]) {
        theEntity = [self.entries.itemClass id: theId];
        [self.entries addObject:theEntity];
    } else {
        theId = [pathComponents[pathComponents.count-2] intValue];
        theEntity = self.entries[theId];
        NSLog(@"editing object %@ id %ld",theEntity,theId);
    }
    for ( NSString *key in data.allKeys) {
        [theEntity setValue: [data objectForKey:key] forKey:key];
    }
    return [self redirectToList];
}


-at:(id<MPWIdentifying>)aReference
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
            self.entries[idString.intValue]=nil;
            return [self redirectToList];
        } else if ( [idString isEqual:@"edit"]) {
            idString=pathComponents[pathComponents.count-2];
            return self.entries[idString.intValue];
        } else {
            return  self.entries[idString.intValue];
        }
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STEntityTable(testing) 

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
