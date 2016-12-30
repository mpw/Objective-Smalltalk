//
//  MPWSqliteScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/16.
//
//

#import "MPWSqliteScheme.h"
#import <ObjectiveSmalltalk/MPWStCompiler.h>
#import <ObjectiveSmalltalk/MPWGenericBinding.h>
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

-(NSArray *)dictionariesForResultSet:(FMResultSet *)resultSet
{
    NSMutableArray *dicts=[NSMutableArray array];
    while ( [resultSet next]) {
        [dicts addObject:[resultSet resultDictionary]];
    }
    return dicts;
}



-(NSArray *)dictionariesForQuery:(NSString *)query
{
    return [self dictionariesForResultSet:[self executeQuery:query]];
}

-contentForPath:(NSArray*)array
{
    if ( [array.firstObject length] == 0) {
        array=[array subarrayWithRange:NSMakeRange(1, array.count-1)];
    }
    if ( [array count] == 3) {
        NSString *table=array[0];
        NSString *column=array[1];
        NSString *value=array[2];
        return [self dictionariesForQuery:[NSString stringWithFormat:@"select * from %@ where %@=%@",table,column,value]];
    } else if ( [array count]==1 && ![array[0] isEqualToString:@"."]) {
        return [self dictionariesForQuery:[NSString stringWithFormat:@"select * from %@ ",array[0]]];
    } else if ( [array count]==0 || ([array count]==1 && [array[0] isEqualToString:@"."])) {
        return [[[self dictionariesForQuery:@"select name from sqlite_master where [type] = 'table'"] collect] objectForKey:@"name"];
    } else {
        return  nil;
    }
}


-(NSArray*)childrenOf:(MPWGenericBinding*)aBinding
{
    NSArray *children=[self valueForBinding:aBinding];
    NSMutableArray *childBindings=[NSMutableArray array];
    for ( NSString *child in children ) {
        if ( [child respondsToSelector:@selector(characterAtIndex:)] ) {
            [childBindings addObject:[MPWGenericBinding bindingWithName:child scheme:self]];
        }
    }
    return childBindings;
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
    [compiler evaluateScriptString:@"scheme:chinook := testscheme"];
    return compiler;
}

+(NSArray *)_resultsForScript:(NSString *)script
{
    MPWStCompiler *compiler=[self _testInterpreter];
    NSArray *results =[compiler evaluateScriptString:script];
    return results;
}

+(void)testBasicDBAccess
{
    NSArray *results =[self _resultsForScript:@"scheme:chinook dictionariesForQuery:'select * from Customers where CustomerID=1;'."];
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}

+(void)testBasicSchemeAccess
{
    NSArray *results =[self _resultsForScript:@"chinook:Customers/CustomerID/1."];
    INTEXPECT([results count], 1, @"number of results");
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}

+(void)testFullTableQuery
{
    NSArray *results =[self _resultsForScript:@"chinook:Customers."];
    INTEXPECT([results count], 59, @"number of results");
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
    d=results.lastObject;
    IDEXPECT( d[@"CustomerId"], @(59), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Puja", @"first name");
}

+(void)testGetSchema
{
    NSArray *results =[self _resultsForScript:@"chinook:."];
    INTEXPECT([results count], 13, @"number of results");
    IDEXPECT( results[0], @"albums", @"first table");
    IDEXPECT( results[1], @"sqlite_sequence", @"2nd table");
    IDEXPECT( results[2], @"artists", @"2nd table");

}

+testSelectors
{
    return @[
             @"testBasicDBAccess",
             @"testBasicSchemeAccess",
             @"testFullTableQuery",
             @"testGetSchema",
             ];
}



@end
