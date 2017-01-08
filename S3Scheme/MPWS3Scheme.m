//
//  MPWS3Scheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 1/7/17.
//
//

#import "MPWS3Scheme.h"
#import <AWSS3/AWSS3.h>
#import <MPWFoundation/NSThreadWaiting.h>
#import <MPWFoundation/MPWFoundation.h>

@interface MPWS3Scheme ()

@property (nonatomic,strong) AWSS3 *s3;

@end



@implementation MPWS3Scheme

-(NSTimeInterval)defaultTimeout
{
    return 5;
}

-(instancetype)init
{
    self=[super init];
    self.s3=[AWSS3 defaultS3];
    self.timeout=[self defaultTimeout];
    return self;
}

-(void)waitForResult:(AWSTask*)task
{
    [NSThread sleepForTimeInterval:self.timeout orUntilConditionIsMet:^NSNumber *{
        return @(task.isCompleted);
    }];
}

-(NSArray<AWSS3Object *>*)listObjectsOfBucket:(NSString *)bucketName
{
    AWSS3ListObjectsRequest *listRequest = [AWSS3ListObjectsRequest new];
    listRequest.bucket=bucketName;
    AWSTask<AWSS3ListObjectsOutput *> *result;
    result=[self.s3 listObjects:listRequest];
    [self waitForResult:result];
    return result.result.contents;
}

-(NSArray<AWSS3Bucket *> *)listBuckets
{
    AWSRequest *listRequest = [AWSRequest new];
    AWSTask<AWSS3ListBucketsOutput *> *result;
    result=[self.s3 listBuckets:listRequest];
    [self waitForResult:result];
    return result.result.buckets;
}

-contentForPath:(NSArray*)array
{
    if ( [array.firstObject length] == 0) {
        array=[array subarrayWithRange:NSMakeRange(1, array.count-1)];
    }
    if ( array.count == 0 ) {
        return [(AWSS3Bucket *)[[self listBuckets] collect] name];
    } else if ( array.count == 1) {
        return [(AWSS3Object *)[[self listObjectsOfBucket:array[0]] collect] key];
    } else {
        return  nil;
    }
}




@end

#import <MPWFoundation/DebugMacros.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>

@implementation MPWScheme(testing)

+_testScheme
{
    MPWS3Scheme *scheme=[self scheme];
    return scheme;
}

+_testInterpreter
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler bindValue:[self _testScheme] toVariableNamed:@"testscheme"];
    [compiler evaluateScriptString:@"scheme:s3 := testscheme"];
    return compiler;
}



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

+(void)testConfiguredWithLocalURL
{
    [self setupCredentials];
    AWSEndpoint *endpoint = [[AWSServiceManager defaultServiceManager] defaultServiceConfiguration].endpoint;
    IDEXPECT([endpoint.URL absoluteString], @"http://localhost:9000", @"local endpoint");
}

+(void)testLocalS3ListBuckets
{
    [self setupCredentials];
    MPWS3Scheme *s=[self _testScheme];
    NSArray<AWSS3Bucket *> *buckets=[s listBuckets];
    INTEXPECT(buckets.count,1,@"number of buckets");
    IDEXPECT(buckets[0].name,@"testbucket1",@"first bucket");
}


+(void)testLocalS3ListContentOfBucket
{
    [self setupCredentials];
    MPWS3Scheme *s=[self _testScheme];
    NSArray<AWSS3Object *> *content=[s listObjectsOfBucket:@"testbucket1"];
    INTEXPECT(content.count,1,@"number of files");
    IDEXPECT(content[0].key,@"alias.py",@"first file in bucket");
}

+(void)testListBucketsViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSArray* content=[interpreter evaluateScriptString:@"s3:/"];
    INTEXPECT(content.count,1,@"number of files");
    IDEXPECT(content[0],@"testbucket1",@"first bucket");
}


+(void)testListBucketContentsViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSArray* content=[interpreter evaluateScriptString:@"s3:/testbucket1"];
    INTEXPECT(content.count,1,@"number of files");
    IDEXPECT(content[0],@"alias.py",@"first file in bucket");
}


+testSelectors
{
    return @[
             @"testConfiguredWithLocalURL",
             @"testLocalS3ListBuckets",
             @"testLocalS3ListContentOfBucket",
             @"testListBucketsViaIdentifer",
             @"testListBucketContentsViaIdentifer",
             ];
}

@end
