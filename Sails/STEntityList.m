//
//  STEntityList.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STEntityList.h"

@interface STEntityList()

@property (nonatomic, strong) NSMutableDictionary *entries;
@property (nonatomic, assign) long maxId;
@property (nonatomic, strong) Class entityClass;



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
