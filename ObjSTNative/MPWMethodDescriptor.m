//
//  MPWMethodDescriptor.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/21/14.
//
//

#import "MPWMethodDescriptor.h"

@implementation MPWMethodDescriptor


objectAccessor(NSString*, symbol, setSymbol)
objectAccessor(NSString*, name, setName)
objectAccessor(NSString*, objcType, setObjcType)

-(void)dealloc
{
    [symbol release];
    [name release];
    [objcType release];
    [super dealloc];
}

@end
