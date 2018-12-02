//
//  AppDelegate.m
//  TestObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.12.18.
//

#import "AppDelegate.h"
#import <MPWTest/MPWTestSuite.h>
#import <MPWTest/MPWLoggingTester.h>
#import <MPWTest/MPWClassMirror.h>
#import <ObjectiveSmalltalk/MPWStCompiler.h>
@interface AppDelegate ()

@end

@implementation AppDelegate



int runTests( NSArray *testSuiteNames , NSArray *testTypeNames,  BOOL verbose ,BOOL veryVerbose ) {
    NSLog(@"will run tests");
    MPWTestSuite* test;
    MPWLoggingTester* results;
    int exitCode=0;
    [MPWStCompiler compiler];
    NSString *testListPath=[[NSBundle mainBundle] pathForResource:@"ClassesToTest"
                                                           ofType:@"plist"];
    NSData *namePlist=[NSData dataWithContentsOfFile:testListPath];
    NSLog(@"got classes to test data");
    sleep(1);

    NSArray *classNamesToTest=[NSPropertyListSerialization propertyListWithData:namePlist options:0 format:0 error:nil];
    NSLog(@"parsed classes to test data");
    sleep(1);
    //    NSArray *classNamesToTest = @[ @"MPWFastInvocation" ];

    NSMutableArray *mirrors=[NSMutableArray array];
    for ( NSString *className in classNamesToTest ) {
        id class = NSClassFromString( className);
        id mirror = [MPWClassMirror mirrorWithClass:class];
        if (mirror) {
            [mirrors addObject:mirror];
            NSLog(@"added mirror for %@",className);
        } else {
            NSLog(@"no mirror for class %@ class %@",className,class);
        }
    }
    NSLog(@"got mirrors");
    test=[MPWTestSuite testSuiteWithName:@"all" classMirrors:mirrors testTypes:@[ @"testSelectors"]];
    NSLog(@"got test suite");


    results=[[MPWLoggingTester alloc] init];
    [results setVerbose:veryVerbose];
    fprintf(stderr,"Will run %d tests\n",[test numberOfTests]);
    sleep(1);
    [results addToTotalTests:[test numberOfTests]];
    [test runTest:results];
    if ( !veryVerbose ){
        if ( verbose) {
            [results printAllResults];
        } else {
            [results printResults];
        }
    }
    if ( [results failureCount] >0 ) {
        exitCode=1;
    }
//    exit(0);
    return exitCode;

}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    runTests( @[ @"MPWFoundation"], @[] , NO, NO);
    return YES;
}


@end
