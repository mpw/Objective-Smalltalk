//
//  STEntity.m
//  Sails
//
//  Created by Marcel Weiher on 05.03.24.
//

#import "STEntity.h"

@interface STEntity()

@property (nonatomic,strong) id id;


@end


@implementation STEntity

+(instancetype)id:theId
{
    return [[[self alloc] initWithId:theId] autorelease];
}

-(instancetype)initWithId:theId
{
    self=[super init];
    self.id = theId;
    return self;
}

-(void)dealloc
{
    [_id release];
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
