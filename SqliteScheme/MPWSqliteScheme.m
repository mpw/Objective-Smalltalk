//
//  MPWSqliteScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/16.
//
//

#import "MPWSqliteScheme.h"
#import <ObjectiveSmalltalk/MPWStCompiler.h>
#import "sqlite3.h"
#import <FMDB/FMDB.h>

@interface MPWSqliteScheme()

@property (nonatomic,strong)  FMDatabase *db;


@end


@implementation MPWSqliteScheme

+(instancetype)schemeWithPath:(NSString *)dbPath
{
    return [[self alloc] initWithPathToDB:dbPath];
}


-(instancetype)initWithPathToDB:(NSString *)dbPath
{
    self=[super init];
    self.db=[FMDatabase databaseWithPath:dbPath];
    [self.db open];
    if ( self.db )  {
        return self;
    } else {
        return nil;
    }
}

-(FMResultSet *)executeQuery:(NSString *)query
{
    return [self.db executeQuery:query];
}

-(NSArray *)dictionariesForQuery:(NSString *)query
{
    FMResultSet *resultSet=[self executeQuery:query];
    NSMutableArray *dicts=[NSMutableArray array];
    while ( [resultSet next]) {
        [dicts addObject:[resultSet resultDictionary]];
    }
    return dicts;
}

-contentForPath:(NSArray*)array
{
    NSString *table=array[0];
    NSString *column=array[1];
    NSString *value=array[2];
    return [self dictionariesForQuery:[NSString stringWithFormat:@"select * from %@ where %@=%@",table,column,value]];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWSqliteScheme(tests)

+_testScheme
{
    NSString *chinookPath=[[NSBundle bundleForClass:self] pathForResource:@"chinook" ofType:@"db"];
    MPWSqliteScheme *scheme=[self schemeWithPath:chinookPath];
    return scheme;
}

+_testInterpreter
{
    MPWStCompiler *compiler=[MPWStCompiler compiler];
    [compiler bindValue:[self _testScheme] toVariableNamed:@"testscheme"];
    [compiler evaluateScriptString:@"scheme:sqlite := testscheme"];
    return compiler;
}

+(void)testBasicDBAccess
{
    MPWStCompiler *compiler=[self _testInterpreter];
    NSArray *results =[compiler evaluateScriptString:@"scheme:sqlite dictionariesForQuery:'select * from Customers where CustomerID=1;'."];
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}

+(void)testBasicSchemeAccess
{
    MPWStCompiler *compiler=[self _testInterpreter];
    NSArray *results =[compiler evaluateScriptString:@"sqlite:Customers/CustomerID/1."];
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}

+testSelectors
{
    return @[
             @"testBasicDBAccess",
             @"testBasicSchemeAccess",
             ];
}

@end
