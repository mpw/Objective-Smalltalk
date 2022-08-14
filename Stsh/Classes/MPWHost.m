//
//  MPWHost.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.07.22.
//

#import "MPWHost.h"
#import <ObjectiveSSH/SSHConnection.h>
#import "MPWShellProcess.h"
#import "MPWCommandStore.h"

@interface MPWRemoteHost : MPWHost
{
    SSHConnection *connection;
}

-(instancetype)initWithName:(NSString*)name user:(NSString*)user;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *user;
objectAccessor_h(SSHConnection*, connection, setConnection)
idAccessor_h( commandStore, setCommandStore)
@end

@interface MPWLocalHost : MPWHost


@end


@implementation MPWHost
{
    MPWCommandStore *commandStore;
}

+(instancetype)localhost
{
    return [[[MPWLocalHost alloc] init] autorelease];
}

+(instancetype)host:(NSString*)name user:(NSString*)user
{
    MPWRemoteHost *host= [[[MPWRemoteHost alloc] initWithName:name user:user] autorelease];
    return host;
}

-(id<MPWStorage>)store
{
    return nil;
}
-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output
{
}

-(NSData*)run:(NSString*)command
{
    return nil;
}

-(id<MPWStorage>)httpBased:(NSString*)scheme port:(int)port
{
    MPWURLSchemeResolver* baseStore=[MPWURLSchemeResolver store];
    MPWURLReference *baseRef=[[[MPWURLReference alloc] initWithPathComponents:@[@"/"] host:self.name scheme:scheme] autorelease];
    baseRef.port = port;
    return [baseStore relativeStoreAt:baseRef];
}


-(id<MPWStorage>)http
{
    return [self httpBased:@"http" port:80];
}

-(id<MPWStorage>)https
{
    return [self httpBased:@"https" port:0 ];
}

-(id<MPWStorage>)createCommandStore
{
    return nil;
}


lazyAccessor(MPWCommandStore, commandStore, setCommandStore, createCommandStore)


@end

@implementation MPWLocalHost


-(id<MPWStorage>)store
{
    return [MPWDiskStore store];
}

-(NSString*)name
{
    return @"localhost";
}

-(NSString*)user
{
    return [[NSProcessInfo processInfo] userName];
}

-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output
{
    NSArray *splitCommand = [command componentsSeparatedByString:@" "];
    command=splitCommand.firstObject;
    NSArray *args=nil;
    if ( splitCommand.count > 1 ) {
        args=[splitCommand subarrayWithRange:NSMakeRange(1,splitCommand.count-1)];
    }
    MPWShellProcess *process=[[[MPWShellProcess alloc] initWithName:command arguments:args] autorelease];
    [process runWithTarget:output];
}


-(NSData*)run:(NSString*)command
{
    MPWByteStream *s=[MPWByteStream stream];
    [self run:command outputTo:s];
    return [s byteTarget];
}

-(id<MPWStorage>)commandStore
{
    return [MPWCommandStore store];
}



@end

@implementation MPWRemoteHost


-(instancetype)initWithName:(NSString*)newName user:(NSString*)newUser
{
    self=[super init];
    self.name=newName;
    self.user=newUser;
    return self;
}

-(BOOL)loadSSHFramework
{
    if ( !NSClassFromString(@"SSHConnection") ) {
        NSBundle *bundle = [NSBundle loadFramework:@"ObjectiveSSH"];
        return [bundle isLoaded];
    }
    return YES;
}


-(SSHConnection*)createConnection
{
    if (![self loadSSHFramework]) {
        NSLog(@"framework not loaded");
        return nil;
    }
    SSHConnection *s=[[[NSClassFromString(@"SSHConnection") alloc] init] autorelease];
    s.host = self.name;
    s.user = self.user;
    return s;
}

lazyAccessor(SSHConnection, connection, setConnection, createConnection)

-(id<MPWStorage>)store
{
    return [[self connection] store];
}

-(id<MPWStorage>)createCommandStore
{
    return [[[NSClassFromString(@"SSHCommandStore") alloc] initWithConnection:self.connection] autorelease];
}


-(void)run:(NSString*)command outputTo:(NSObject <Streaming>*)output
{
    [[self connection] run:command outputTo:output];
}

-(NSData*)run:(NSString*)command
{
    return [[self connection] run:command];
}


@synthesize name,user;

@end

