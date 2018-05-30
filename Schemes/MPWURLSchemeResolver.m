//
//  MPWURLSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWURLSchemeResolver.h"
#import "MPWURLBinding.h"
#import "MPWResource.h"

@interface MPWURLSchemeResolver ()

@property (nonatomic,strong) NSString* schemePrefix;


@end


@implementation MPWURLSchemeResolver

-(instancetype)initWithSchemePrefix:(NSString *)schemeName
{
    self=[super init];
    self.schemePrefix=schemeName;
    return self;
}

-(instancetype)init
{
    return [self initWithSchemePrefix:@"http"];
}

+(instancetype)httpScheme
{
    return [[[self alloc] initWithSchemePrefix:@"http"] autorelease];
}

+(instancetype)httpsScheme
{
    return [[[self alloc] initWithSchemePrefix:@"https"] autorelease];
}


-(MPWURLBinding*)bindingForName:aName inContext:aContext
{
    id urlbinding = [[[MPWURLBinding alloc] initWithURLString:[[[self schemePrefix] stringByAppendingString:@":" ] stringByAppendingString:aName]] autorelease];
	return urlbinding;
}

-(id)objectForReference:(id)aReference
{
    NSError *error=nil;
    NSURL *aURL=[aReference asURL];
    NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
    MPWResource *result=[[[MPWResource alloc] init] autorelease];
    [result setSource:aURL];
    [result setRawData:rawData];
    [result setError:error];
    return result;
}


@end


@implementation MPWURLSchemeResolver(tests)


+(void)testScuritySetting
{
    IDEXPECT( [[self httpScheme] schemePrefix], @"http",@"insecure");
    IDEXPECT( [[self httpsScheme] schemePrefix], @"https",@"secure");
    IDEXPECT( [[(MPWURLBinding*)[[self httpsScheme] bindingForName:@"//localhost" inContext:nil] url] absoluteString], @"https://localhost",@"secure");
    IDEXPECT( [[(MPWURLBinding*)[[[[self alloc] initWithSchemePrefix:@"ftp" ] autorelease] bindingForName:@"localhost" inContext:nil] url] absoluteString], @"ftp:localhost" ,@"ftp");
    
}

+(NSArray*)testSelectors
{
    return @[
             @"testScuritySetting",
             ];
}

@end
