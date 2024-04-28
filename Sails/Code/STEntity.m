//
//  STEntity.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STEntity.h"

@interface STEntity()

@property (nonatomic,assign) long id;


@end


@implementation STEntity

+(instancetype)id:(long)theId
{
    return [[[self alloc] initWithId:theId] autorelease];
}

-(instancetype)initWithId:(long)theId
{
    self=[super init];
    self.id = theId;
    return self;
}

-allKeys
{
    NSArray *ivarNames =  [[[[self class] instanceVariables] collect] name];
    return [ivarNames subarrayWithRange:NSMakeRange(2, ivarNames.count - 2 )];
}

-copyWithZone:aZone
{
    return [self retain];
}

-(void)dealloc
{
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STEntity(testing) 

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
