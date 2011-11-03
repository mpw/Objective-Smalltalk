//
//  MethodDict.m
//  MPWTalk
//
//  Created by Marcel Weiher on 10/16/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MethodDict.h"
#import <MPWFoundation/MPWFoundation.h>
#import <MPWTalk/MPWMethodHeader.h>

@implementation NSString(methodName)

-methodName
{
    MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:self];
    return [header methodName];
}

@end

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
    NSMutableDictionary *d=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainers format:nil errorDescription:nil];
    [self setDict:d];
    return self;
}

-(NSArray*)classes
{
    return [[[self dict] allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

-(NSArray*)methodsForClass:(NSString*)className
{
    return [(NSArray*)[[[[[self dict] objectForKey:className] allKeys] collect] methodName] sortedArrayUsingSelector:@selector(compare:)];
}

-(NSString*)fullNameForMethodName:(NSString*)shortName ofClass:(NSString*)className
{
    NSArray *fullNames = [[[self dict] objectForKey:className] allKeys];
    for ( NSString *fullName in fullNames ) {
        if ( [[fullName methodName] isEqual:shortName] ) {
            return fullName;
        }
    }
    return nil;
}

-(NSString*)methodForClass:(NSString*)className methodName:(NSString*)methodName
{
    
    return [[[self dict] objectForKey:className] objectForKey:[self fullNameForMethodName:methodName ofClass:className]];
}

-(void)setMethod:(NSString*)methodBody name:(NSString*)methodName  forClass:(NSString*)className
{
    NSMutableDictionary *perClassDict = [[self dict] objectForKey:className];
    if ( !perClassDict ) {
        perClassDict=[NSMutableDictionary dictionary];
        [[self dict] setObject:perClassDict forKey:className];
    }
    [perClassDict setObject:methodBody forKey:methodName];
}



-(void)deleteMethodName:(NSString*)methodName forClass:(NSString*)className
{ 
    [[[self dict] objectForKey:className] removeObjectForKey:[self fullNameForMethodName:methodName ofClass:className]];
}

@end