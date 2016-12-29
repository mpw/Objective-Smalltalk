//
//  MPWSqliteScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/16.
//
//

#import "MPWSqliteScheme.h"
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



@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWSqliteScheme(tests)

+_testScheme
{
    NSString *chinookPath=[[NSBundle bundleForClass:self] pathForResource:@"chinook" ofType:@"db"];
    MPWSqliteScheme *scheme=[self schemeWithPath:chinookPath];
    return scheme;
}


+(void)testBasicDBAccess
{
    MPWSqliteScheme *scheme=[self _testScheme];
    EXPECTNOTNIL(scheme, @"db");
    FMResultSet *results =[scheme executeQuery:@"select * from Customers where CustomerID=1;"];
    EXPECTTRUE([results next], @"has at least one row ");
    
}

+testSelectors
{
    return @[
             @"testBasicDBAccess",
             ];
}

@end
