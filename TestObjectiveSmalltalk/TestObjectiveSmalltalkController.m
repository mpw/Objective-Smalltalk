//
//  ViewController.m
//  TestObjectiveSmalltalk
//
//  Created by Marcel Weiher on 02.12.18.
//

#import "TestObjectiveSmalltalkController.h"
#import <MPWTest/MPWTestSuite.h>
#import <MPWTest/MPWLoggingTester.h>
#import <ObjectiveSmalltalk/MPWClassMirror.h>
#import <ObjectiveSmalltalk/STCompiler.h>
#import <ObjectiveSmalltalk/STTests.h>
#import <ObjectiveSmalltalk/STCompiler.h>
#import <ObjectiveSmalltalk/NSObjectScripting.h>

@interface TestObjectiveSmalltalkController ()

@property (nonatomic,strong)   MPWLoggingTester *results;

@end

@implementation TestObjectiveSmalltalkController



-(int)runTests:(NSArray *)testSuiteNames testTypes:(NSArray *)testTypeNames verbose:(BOOL)verbose veryVerbose:(BOOL) veryVerbose {
    NSLog(@"will run tests");
    MPWTestSuite* test;
    int exitCode=0;
    [STCompiler compiler];
    [STTests compiler];
    NSString *testListPath=[[NSBundle mainBundle] pathForResource:@"ClassesToTest"
                                                           ofType:@"plist"];
    NSData *namePlist=[NSData dataWithContentsOfFile:testListPath];
    NSLog(@"got classes to test data");
//    amIHereFunc();
    
    NSArray *classNamesToTest=[NSPropertyListSerialization propertyListWithData:namePlist options:0 format:0 error:nil];

//    classNamesToTest = @[ @"MPWStTests", /* @"MPWMethodCallBack"  */];  //
    NSLog(@"parsed classes to test data");

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


    self.results=[[MPWLoggingTester alloc] init];
    [self.results setVerbose:veryVerbose];
    fprintf(stderr,"Will run %d tests\n",[test numberOfTests]);
    [self.results addToTotalTests:[test numberOfTests]];
    [test runTest:self.results];
    if ( !veryVerbose ){
        if ( verbose) {
            [self.results printAllResults];
        } else {
            [self.results printResults];
        }
    }
    if ( [self.results failureCount] >0 ) {
        exitCode=1;
    }
//    exit(0);
    return exitCode;

}



- (void)viewDidLoad {
    [super viewDidLoad];
    [self runTests:@[ @"MPWFoundation"] testTypes:@[] verbose:NO veryVerbose:NO];

    if ( self.results.failureCount > 0) {
        [self.failure setText:[NSString stringWithFormat:@"%ld failures",self.results.failureCount]];
        [self.failure setTextColor:[UIColor redColor]];
    } else {
        [self.failure setText:[NSString stringWithFormat:@"0 failures"]];
        [self.failure setTextColor:[UIColor greenColor]];
    }
    [self.success setText:[NSString stringWithFormat:@"%ld successes",self.results.successCount]];
    
    // Do any additional setup after loading the view, typically from a nib.
}


@end
