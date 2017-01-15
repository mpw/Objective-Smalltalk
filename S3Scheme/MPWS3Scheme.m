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
#import <ObjectiveSmalltalk/MPWGenericBinding.h>

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
    [[AWSLogger defaultLogger] setLogLevel:0];
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
    if ( result.error) {
        NSLog(@"listObjectsOfBucket error: %@",result.error);
    }
    return result.result.contents;
}

-(NSArray<AWSS3Bucket *> *)listBuckets
{
    AWSRequest *listRequest = [AWSRequest new];
    AWSTask<AWSS3ListBucketsOutput *> *result;
    result=[self.s3 listBuckets:listRequest];
    [self waitForResult:result];
    if ( result.error) {
        NSLog(@"listBuckets error: %@",result.error);
    }
    return result.result.buckets;
}

-(AWSS3GetObjectOutput *)getObject:(NSString*)objectName inBucket:(NSString *)bucketName
{
    AWSS3GetObjectRequest *objectRequest = [AWSS3GetObjectRequest new];
    objectRequest.bucket=bucketName;
    objectRequest.key=objectName;
    AWSTask<AWSS3GetObjectOutput *> *result;
    result=[self.s3 getObject:objectRequest];
    [self waitForResult:result];
    if ( result.error) {
        NSLog(@"GET error: %@",result.error);
    }
    return result.result;
}

-(void)putObject:(NSData*)data forKey:(NSString*)objectName inBucket:(NSString *)bucketName
{
    AWSS3PutObjectRequest *objectRequest = [AWSS3PutObjectRequest new];
    objectRequest.bucket=bucketName;
    objectRequest.key=objectName;
    objectRequest.body=[data asData];
    objectRequest.contentType=@"text/plain";
    AWSTask<AWSS3PutObjectOutput *> *result;
    result=[self.s3 putObject:objectRequest];
    [self waitForResult:result];
    if ( result.error) {
        NSLog(@"PUT error: %@",result.error);
    }
    
}

-(void)deleteObject:(NSString*)objectName inBucket:(NSString *)bucketName
{
    AWSS3DeleteObjectRequest *objectRequest = [AWSS3DeleteObjectRequest new];
    objectRequest.bucket=bucketName;
    objectRequest.key=objectName;
    AWSTask<AWSS3DeleteObjectOutput *> *result;
    result=[self.s3 deleteObject:objectRequest];
    [self waitForResult:result];
}


-(void)setValue:newValue forBinding:aBinding
{
    NSArray *pathArray=[self pathArrayForPathString:[aBinding path]];
    if ( [pathArray.firstObject length] == 0) {
        pathArray=[pathArray subarrayWithRange:NSMakeRange(1, pathArray.count-1)];
    }
    if ( pathArray.count >= 2) {
        NSString *key=[[pathArray subarrayWithRange:NSMakeRange(1,pathArray.count-1)] componentsJoinedByString:@"/"];
        if ( newValue ) {
            [self putObject:newValue forKey:key inBucket:pathArray[0]];
        } else {
            [self deleteObject:key inBucket:pathArray[0]];
        }
    }
}


-contentForPath:(NSArray*)array
{
//    NSLog(@"content for path: %@",array);
    if ( [array.firstObject length] == 0 || [array.firstObject isEqualToString:@"."]) {
        array=[array subarrayWithRange:NSMakeRange(1, array.count-1)];
    }
    if ( array.count == 0) {
        return [(AWSS3Bucket *)[[self listBuckets] collect] name];
    } else if ( array.count == 1) {
        NSArray *names=(NSArray*)[(AWSS3Object *)[[self listObjectsOfBucket:array[0]] collect] key];
        return names;
    } else if ( array.count >= 2) {
        NSString *key=[[array subarrayWithRange:NSMakeRange(1,array.count-1)] componentsJoinedByString:@"/"];
        return [self getObject:key inBucket:array[0]].body;
    } else {
        
        return  nil;
    }
}

-(NSArray*)childrenOf:(MPWGenericBinding*)aBinding
{
//    NSLog(@"childrenOf: %@",[aBinding name]);
    NSArray *children=[self valueForBinding:aBinding];
//    NSLog(@"children: %@",children);
    NSMutableArray *childBindings=[NSMutableArray array];
    for ( NSString *child in children ) {
        if ( [child respondsToSelector:@selector(characterAtIndex:)] ) {
//            NSLog(@"create binding for: %@",child);
            [childBindings addObject:[MPWGenericBinding bindingWithName:child scheme:self]];
        }
    }
//    NSLog(@"bindings: %@",children);
    return childBindings;
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



+(void)setupHost:(NSString *)hostURLString accessKey:(NSString *)accessKey secretKey:(NSString *)secretKey
{
    if (![AWSServiceManager defaultServiceManager].defaultServiceConfiguration) {
        AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:accessKey   secretKey:secretKey];
        AWSEndpoint *endpoint=[[AWSEndpoint alloc] initWithURLString:hostURLString];
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionEUCentral1
                                                                                        endpoint:endpoint
                                                                             credentialsProvider:credentialsProvider];
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
        
    }
}

+(void)setupCredentials
{
    [self setupHost:@"http://localhost:9000" accessKey:@"9JMQ8HKK92R8W65WA16T" secretKey:@"mvmW9N6hhiyo15OZf6boV3DRe+TDx0keAkqhJgAu"];
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
    INTEXPECT(content.count,2,@"number of files");
    IDEXPECT(content[0].key,@"alias.py",@"first file in bucket");
    IDEXPECT(content[1].key,@"folder/hello.txt",@"file in subfolder");
}

+(void)testListBucketsViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSArray* content=[interpreter evaluateScriptString:@"s3:/"];
    INTEXPECT(content.count,1,@"number of files");
    IDEXPECT(content[0],@"testbucket1",@"first bucket");
}


+(void)testListBucketContentListViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSArray* content=[interpreter evaluateScriptString:@"s3:/testbucket1"];
    INTEXPECT(content.count,2,@"number of files");
    IDEXPECT(content[0],@"alias.py",@"first file in bucket");
    IDEXPECT(content[1],@"folder/hello.txt",@"file in folder");
}

+(void)testGetBucketContentsViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSData* aliaspy=[interpreter evaluateScriptString:@"s3:/testbucket1/alias.py"];
    INTEXPECT(aliaspy.length, 11138, @"length");
}

+(void)testGetBucketFolderContentsViaIdentifer
{
    [self setupCredentials];
    MPWStCompiler *interpreter = [self _testInterpreter];
    NSData* aliaspy=[interpreter evaluateScriptString:@"s3:/testbucket1/folder/hello.txt"];
    INTEXPECT(aliaspy.length, 12, @"length");
}



+testSelectors
{
    return @[
             @"testConfiguredWithLocalURL",
             @"testLocalS3ListBuckets",
             @"testLocalS3ListContentOfBucket",
             @"testListBucketsViaIdentifer",
             @"testListBucketContentListViaIdentifer",
             @"testGetBucketContentsViaIdentifer",
             @"testGetBucketFolderContentsViaIdentifer",
             ];
}

@end
