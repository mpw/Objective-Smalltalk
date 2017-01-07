//
//  MPWS3Scheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/7/17.
//
//

#import "MPWS3Scheme.h"
#import <AWSS3/AWSS3.h>

@implementation MPWS3Scheme

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWScheme(testing)

+(void)setupCredentials
{
    if (![AWSServiceManager defaultServiceManager].defaultServiceConfiguration) {
        AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:@"9JMQ8HKK92R8W65WA16T"   secretKey:@"mvmW9N6hhiyo15OZf6boV3DRe+TDx0keAkqhJgAu"];
        AWSEndpoint *endpoint=[[AWSEndpoint alloc] initWithURLString:@"http://localhost:9000"];
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1
                                                                                        endpoint:endpoint
                                                                             credentialsProvider:credentialsProvider];
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
        
    }
}



+(void)testLocalS3ListBuckets
{
    [self setupCredentials];
    AWSS3 *s3 = [AWSS3 defaultS3];

    AWSEndpoint *endpoint = [[AWSServiceManager defaultServiceManager] defaultServiceConfiguration].endpoint;
    
    
    IDEXPECT([endpoint.URL absoluteString], @"http://localhost:9000", @"local endpoint");
    AWSRequest *listRequest = [AWSRequest new];
    AWSTask<AWSS3ListBucketsOutput *> *result;
    result=[s3 listBuckets:listRequest];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    EXPECTNIL([result error],@"ls error");
//    IDEXPECT([result error],@"",@"ls error");
    AWSS3ListBucketsOutput *payload=result.result;
    NSArray<AWSS3Bucket *> *buckets=payload.buckets;
    INTEXPECT(buckets.count,1,@"number of buckets");
    IDEXPECT(buckets[0].name,@"testbucket1",@"first bucket");
}

+(void)testLocalS3ListContentOfBucket
{
    [self setupCredentials];
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSEndpoint *endpoint = [[AWSServiceManager defaultServiceManager] defaultServiceConfiguration].endpoint;
    
    
    IDEXPECT([endpoint.URL absoluteString], @"http://localhost:9000", @"local endpoint");
    AWSS3ListObjectsRequest *listRequest = [AWSS3ListObjectsRequest new];
    listRequest.bucket=@"testbucket1";
    AWSTask<AWSS3ListObjectsOutput *> *result;
    result=[s3 listObjects:listRequest];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    EXPECTNIL([result error],@"ls error");
//    IDEXPECT([result error],@"",@"ls error");
    AWSS3ListObjectsOutput *payload=result.result;
    NSArray<AWSS3Object *> *content=payload.contents;
    INTEXPECT(content.count,1,@"number of files");
    IDEXPECT(content[0].key,@"alias.py",@"first file in bucket");
}


+testSelectors
{
    return @[
             @"testLocalS3ListBuckets",
             @"testLocalS3ListContentOfBucket",
             ];
}

@end
