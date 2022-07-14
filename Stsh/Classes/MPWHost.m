//
//  MPWHost.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.07.22.
//

#import "MPWHost.h"
#import <ObjectiveSSH/SSHConnection.h>
#import "MPWShellProcess.h"

@interface MPWRemoteHost : MPWHost
{
    SSHConnection *connection;
}

-(instancetype)initWithName:(NSString*)name user:(NSString*)user;

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *user;
objectAccessor_h(SSHConnection, connection, setConnection)
@end

@interface MPWLocalHost : MPWHost


@end


@implementation MPWHost

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
    MPWShellProcess *process=[[[MPWShellProcess alloc] initWithName:command arguments:nil] autorelease];
    [process runWithTarget:output];
}


-(NSData*)run:(NSString*)command
{
    MPWByteStream *s=[MPWByteStream stream];
    [self run:command outputTo:s];
    return [s byteTarget];
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

