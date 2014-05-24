//
//  MPWDirectoryBinding.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/24/14.
//
//

#import "MPWDirectoryBinding.h"

@implementation MPWDirectoryBinding

objectAccessor(NSArray, contents, setContents)

-(instancetype)initWithContents:(NSArray *)newContents
{
    self=[super init];
    [self setContents:newContents];
    return self;
}


-(void)dealloc
{
    [contents release];
    [super dealloc];
}

-(void)writeOnShellPrinter:aPrinter
{
    [aPrinter writeDirectory:self];
}

@end
