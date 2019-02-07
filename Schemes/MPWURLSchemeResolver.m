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

-(id)referenceForPath:(NSString *)name
{
    NSLog(@"referenceForPath: %@",name);
    id <MPWReferencing> reference=[super referenceForPath:name];
    reference.schemeName=[self schemePrefix];
    return reference;
}

//-bindingForReference:aReference inContext:aContext
//{
//    MPWURLBinding* urlbinding = [[[MPWURLBinding alloc] initWithURLString:[[[self schemePrefix] stringByAppendingString:@":" ] stringByAppendingString:[aReference path]]] autorelease];
//    urlbinding.store=self;
//    urlbinding.reference=aReference;
//    return urlbinding;
//}

-(id)objectForReference:(id)aReference
{
    NSError *error=nil;
    NSURL *aURL=[aReference URL];
#ifdef GS_API_LATEST
    NSData *rawData = [NSData dataWithContentsOfURL:aURL];
#else
    NSData *rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
#endif
    MPWResource *result=[[[MPWResource alloc] init] autorelease];
    [result setSource:aURL];
    [result setRawData:rawData];
    [result setError:error];
    return result;
}


///----- support for HOM-based argument-construction

-(NSString*)mimeTypeForData:(NSData*)rawData andResponse:(NSURLResponse*)aResponse
{
    NSString *mime = [aResponse MIMEType];
    const char *ptr=[rawData bytes];
    if ( ptr && [rawData length]) {
        if (( !mime ||  [mime isEqualToString:@"text/html"] ||  [mime isEqualToString:@"text/plain"] )&& (*ptr == '{' || *ptr == '[' )) {
            mime=@"application/json";
        }
    }
    return mime;
}

-(MPWResource*)resourceWithRequest:(NSURLRequest*)request
{
    NSHTTPURLResponse *response=nil;
    NSError *localError=nil;
    NSData *rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if ( [response statusCode] != 404 ) {
        MPWResource *result=[[[MPWResource alloc] init] autorelease];
        [result setSource:[request URL]];
        [result setRawData:rawData];
        [result setMIMEType:[self mimeTypeForData:rawData andResponse:response]];
        return result;
    } else {
        return nil;
    }
}

-_valueWithURL:(NSURL*)aURL
{
    NSMutableURLRequest *request=[[[NSMutableURLRequest alloc] initWithURL:aURL] autorelease];
    NSMutableDictionary *headers=[NSMutableDictionary dictionaryWithObject:@"locale=en-us" forKey:@"Cookies"];
    [headers setObject:@"stsh" forKey:@"User-Agent"];
    [headers setObject:@"*/*" forKey:@"Accept"];
    [request setAllHTTPHeaderFields:headers];
    return [self resourceWithRequest:request];
}



@end


@implementation MPWURLSchemeResolver(tests)


+(void)testScuritySetting
{
    IDEXPECT( [[self httpScheme] schemePrefix], @"http",@"insecure");
    IDEXPECT( [[self httpsScheme] schemePrefix], @"https",@"secure");
    IDEXPECT( [[(MPWGenericReference*)[[self httpsScheme] referenceForPath:@"localhost"] URL] absoluteString], @"https://localhost",@"secure");
    IDEXPECT( [[(MPWGenericReference*)[[[[self alloc] initWithSchemePrefix:@"ftp" ] autorelease] referenceForPath:@"localhost"] URL] absoluteString], @"ftp://localhost" ,@"ftp");
    
}

+(NSArray*)testSelectors
{
    return @[
//             @"testScuritySetting",
             ];
}

@end
