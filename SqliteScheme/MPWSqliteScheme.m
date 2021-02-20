//
//  MPWSqliteScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/16.
//
//

#import "MPWSqliteScheme.h"
#import <ObjectiveSmalltalk/STCompiler.h>
#import <ObjectiveSmalltalk/MPWURLBinding.h>
#import <ObjectiveSmalltalk/STMessagePortDescriptor.h>
#import <MPWFoundation/MPWFoundation.h>
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

+(instancetype)schemeWithRef:(MPWURLBinding *)dbPath
{
    return [self schemeWithPath:[dbPath path]];
}

-(void)setPath:(NSString *)dbPath
{
    self.db=[FMDatabase databaseWithPath:dbPath];
    [self.db open];
}

-(NSString *)path
{
    return self.db.databasePath;
}

-(instancetype)initWithPathToDB:(NSString *)dbPath
{
    self=[super init];
    [self setPath:dbPath];
    if ( self.db )  {
        return self;
    } else {
        return nil;
    }
}

-initWithDictionary:(NSDictionary*)newDict
{
    NSString *path=newDict[@"path"];
    if ( [path respondsToSelector:@selector(path)] ) {
        path=[(id)path path];
    }
    return [self initWithPathToDB:path];
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
    if ( [array count] == 3) {
        NSString *table=array[0];
        NSString *column=array[1];
        NSString *value=array[2];
        return [self dictionariesForQuery:[NSString stringWithFormat:@"select * from %@ where %@='%@'",table,column,value]];
    } else if ( [array count]==1 && ![array[0] isEqualToString:@"."]) {
        return [self dictionariesForQuery:[NSString stringWithFormat:@"select * from %@ ",array[0]]];
    } else if ( [array count]==0 || ([array count]==1 && [array[0] isEqualToString:@"."])) {
        return [[[self dictionariesForQuery:@"select name from sqlite_master where [type] = 'table'"] collect] objectForKey:@"name"];
    } else {
        return  nil;
    }
}

-(id)at:(id)aReference
{
    return [self contentForPath:[aReference relativePathComponents]];
}

-(void)setValue:newValue forBinding:aBinding
{
    NSArray *pathArray=[(MPWGenericReference*)[aBinding reference] relativePathComponents];
    if ( pathArray.count== 1 ) {
        NSString *table=pathArray[0];
        NSMutableString *queryString=[NSMutableString stringWithFormat:@"insert into %@ ",table];
        NSDictionary *d=newValue;
        NSMutableString *sqlKeys=[NSMutableString string];
        NSMutableString *sqlValues=[NSMutableString string];
        NSString *separator=@" ";
        for ( NSString *key in d.allKeys) {
            [sqlKeys appendFormat:@"%@ %@",separator,key];
            [sqlValues appendFormat:@"%@ \"%@\"",separator,d[key]];
            
            separator=@", ";
        }
        [queryString appendFormat:@"( %@ ) VALUES ( %@ )",sqlKeys,sqlValues];
       [self.db executeUpdate:queryString withParameterDictionary:d];
        
    }
    if ( pathArray.count== 3) {
        NSString *table=pathArray[0];
        NSString *column=pathArray[1];
        NSString *value=pathArray[2];
        
        NSDictionary *d=newValue;
        NSMutableString *queryString;
        if ( d ) {
            queryString=[NSMutableString stringWithFormat:@"update %@ set ",table];
            BOOL first=YES;
            for ( NSString *key in d.allKeys) {
                [queryString appendFormat:@" %c %@ = :%@ ",!first ? ',':' ',key,key];
                first=NO;
            }
        } else {
            queryString=[NSMutableString stringWithFormat:@"delete from %@ ",table];
        }
        [queryString appendFormat:@" where %@ = '%@'",column,value];
        NSLog(@"update query string: %@",queryString);
        [self.db executeUpdate:queryString withParameterDictionary:d];
    }
}


-(void)delete:(MPWGenericReference *)aRefence
{
    [self setValue:nil forBinding:aRefence];
}

// FIXME: this code is duplicated, for example in MPWS3Scheme

-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference
{
    NSArray *children=[self at:aReference];
    NSMutableArray *childReferences=[NSMutableArray array];
    for ( NSString *child in children ) {
        if ( [child respondsToSelector:@selector(characterAtIndex:)] ) {
            [childReferences addObject:[self referenceForPath:child]];
        }
    }
    return childReferences;
}

-defaultInputPort
{
    return [[STMessagePortDescriptor alloc] initWithTarget:self key:@"path" protocol:nil sends:YES];
}



@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWSqliteScheme(tests)

+_chinookPath
{
    return [[NSBundle bundleForClass:self] pathForResource:@"chinook" ofType:@"db"];
}


+_testInterpreter
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler bindValue:[self schemeWithPath:[self _chinookPath]] toVariableNamed:@"testscheme"];
    [compiler evaluateScriptString:@"scheme:chinook := testscheme"];
    return compiler;
}

-(void)attachDB:(NSString*)path
{
    NSString *attach=[NSString stringWithFormat:@"attach '%@' as filedb;",path];
    [[self executeQuery:attach] next];
}

-(void)copyTable:(NSString *)dest fromOrigin:(NSString *)source
{
    NSString *copy=[NSString stringWithFormat:@"CREATE TABLE %@ AS SELECT * FROM filedb.%@;",dest,source];
    [[self executeQuery:copy] next];
}

-(void)detachdb
{
    [[self executeQuery:@"DETACH filedb;"] next];
}

+memoryTestScheme
{
    MPWSqliteScheme *scheme=[self schemeWithPath:nil];
    [scheme attachDB:[self _chinookPath]];
    [scheme copyTable:@"mcustomers" fromOrigin:@"Customers"];
    [scheme detachdb];
    return scheme;
}

+_memoryTestInterpreter
{
    STCompiler *compiler=[STCompiler compiler];
    [compiler bindValue:[self memoryTestScheme] toVariableNamed:@"testscheme"];
    [compiler evaluateScriptString:@"scheme:memdb := testscheme."];
    return compiler;
}

+(NSArray *)_resultsForScript:(NSString *)script
{
    STCompiler *compiler=[self _testInterpreter];
    NSArray *results =[compiler evaluateScriptString:script];
    return results;
}

+(NSArray *)_memDBResultsForScript:(NSString *)script
{
    STCompiler *compiler=[self _memoryTestInterpreter];
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

+(void)testBasicMemoryDBSchemeAccess
{
    NSArray *results =[self _memDBResultsForScript:@"memdb:mcustomers "];
    INTEXPECT([results count], 59, @"number of results");
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}

+(void)testBasicMemoryDBAccess
{
    MPWSqliteScheme *scheme=[self schemeWithPath:nil];
    [scheme attachDB:[[self class] _chinookPath]];
    [scheme copyTable:@"bar" fromOrigin:@"Customers"];
    [scheme detachdb];
    NSArray *results=[scheme dictionariesForQuery:@"select * from bar;"];
    INTEXPECT([results count], 59, @"number of results");
    NSDictionary *d=results[0];
    IDEXPECT( d[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( d[@"FirstName"], @"Luís", @"first name");
}


+(void)testSimpleSingleRecordUpdate
{
    STCompiler *compiler=[self _memoryTestInterpreter];
    
    [compiler evaluateScriptString:@"c1 := memdb:mcustomers/CustomerId/1 firstObject mutableCopy autorelease."];
    NSDictionary *before=[compiler evaluateScriptString:@"c1"];
    
    IDEXPECT( before[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( before[@"FirstName"], @"Luís", @"first name");
    [compiler evaluateScriptString:@"var:c1/FirstName := 'Jose'."];
    [compiler evaluateScriptString:@"var:c1/CustomerId := nil."];
    [compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1 := c1."];
    NSDictionary *after=[[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1"] firstObject];
    IDEXPECT( after[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( after[@"FirstName"], @"Jose", @"first name");
    NSDictionary *after2=[[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/2"] firstObject];
    IDEXPECT( after2[@"CustomerId"], @(2), @"customer id");
    IDEXPECT( after2[@"FirstName"], @"Leonie", @"make sure we don't affect other records");
}

+(void)testSimpleDeleteRecord
{
    STCompiler *compiler=[self _memoryTestInterpreter];
    
    NSDictionary *before=[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1 firstObject."];
    IDEXPECT( before[@"FirstName"], @"Luís", @"first name");
    [compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1 := nil."];
    NSDictionary *after=[[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1"] firstObject];
    EXPECTNIL(after,@"should be gone");
}

+(void)testDeleteViaRef
{
    STCompiler *compiler=[self _memoryTestInterpreter];
    NSDictionary *before=[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1 firstObject."];
    IDEXPECT( before[@"FirstName"], @"Luís", @"first name");
    [compiler evaluateScriptString:@"ref:memdb:mcustomers/CustomerId/1 delete."];
    NSDictionary *after=[[compiler evaluateScriptString:@"memdb:mcustomers/CustomerId/1"] firstObject];
    EXPECTNIL(after,@"should be gone");
}

+(void)testInsert
{
    STCompiler *compiler=[self _memoryTestInterpreter];
    
    [compiler evaluateScriptString:@"c1 := memdb:mcustomers/CustomerId/1 firstObject mutableCopy autorelease."];
    NSDictionary *before=[compiler evaluateScriptString:@"c1"];
    INTEXPECT( [[compiler evaluateScriptString:@"memdb:mcustomers count."] intValue],59,@"number of records");
    IDEXPECT( before[@"CustomerId"], @(1), @"customer id");
    IDEXPECT( before[@"FirstName"], @"Luís", @"first name");
    EXPECTNIL( [[compiler evaluateScriptString:@"memdb:mcustomers/LastName/Ambrosio ."] firstObject], @"name to be inserter");;
    [compiler evaluateScriptString:@"var:c1/FirstName := 'Jose'."];
    [compiler evaluateScriptString:@"var:c1/LastName := 'Ambrosio'."];
    [compiler evaluateScriptString:@"var:c1/CustomerId := nil."];
    [compiler evaluateScriptString:@"memdb:mcustomers := c1."];             // should be +=
    INTEXPECT( [[compiler evaluateScriptString:@"memdb:mcustomers count."] intValue],60,@"number of records after insert");
//    EXPECTNOTNIL( [[compiler evaluateScriptString:@"memdb:mcustomers/LastName/Ambrosio ."] firstObject], @"name to be inserted");;
}


+testSelectors
{
    return @[
             @"testBasicDBAccess",
             @"testBasicSchemeAccess",
             @"testFullTableQuery",
             @"testGetSchema",
             @"testBasicMemoryDBSchemeAccess",
             @"testBasicMemoryDBAccess",
             @"testSimpleSingleRecordUpdate",
             @"testSimpleDeleteRecord",
             @"testInsert",
             ];
}



@end
