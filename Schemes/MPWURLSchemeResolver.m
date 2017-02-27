//
//  MPWURLSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWURLSchemeResolver.h"
#import "MPWURLBinding.h"

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


@end


@implementation MPWURLSchemeResolver(tests)


+(void)testScuritySetting
{
    IDEXPECT( [[self httpScheme] schemePrefix], @"http",@"insecure");
    IDEXPECT( [[self httpsScheme] schemePrefix], @"https",@"secure");
    IDEXPECT( [[[[self httpsScheme] bindingForName:@"//localhost" inContext:nil] url] absoluteString], @"https://localhost",@"secure");
    IDEXPECT( [[[[[[self alloc] initWithSchemePrefix:@"ftp" ] autorelease] bindingForName:@"localhost" inContext:nil] url] absoluteString], @"ftp:localhost" ,@"ftp");
    
}

+(NSArray*)testSelectors
{
    return @[
             @"testScuritySetting",
             ];
}

@end
