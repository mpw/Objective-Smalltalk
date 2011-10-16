//
//  MethodDict.m
//  MPWTalk
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MethodDict.h"
#import <MPWFoundation/MPWFoundation.h>

@implementation MethodDict


objectAccessor(NSMutableDictionary, dict, setDict)


- (NSData *)asXml
{
    NSData *data=[NSPropertyListSerialization dataFromPropertyList:[self dict] format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    return data;
}

-initWithXml:(NSData*)data
{
    self = [super init];
    NSDictionary *d=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:nil];
    [self setDict:d];
    return self;
}

-(NSArray*)classes
{
    return [[self dict] allKeys];
}

-(NSArray*)methodsForClass:(NSString*)className
{
    return [[[self dict] objectForKey:className] allKeys];
}

-(NSString*)methodForClass:(NSString*)className methodName:(NSString*)methodName
{
    return [[[self dict] objectForKey:className] objectForKey:methodName];
}

-(void)_setMethod:(NSString*)methodBody name:(NSString*)methodName  forClass:(NSString*)className
{
    NSMutableDictionary *perClassDict = [[self dict] objectForKey:className];
    if ( !perClassDict ) {
        perClassDict=[NSMutableDictionary dictionary];
        [[self dict] setObject:perClassDict forKey:className];
    }
    [perClassDict setObject:methodBody forKey:methodName];
}



-(void)_deleteMethodName:(NSString*)methodName forClass:(NSString*)className
{ 
    [[[self dict] objectForKey:className] removeObjectForKey:methodName];
}

@end
