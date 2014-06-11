//
//  MPWDirectoryBinding.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/24/14.
//
//

#import "MPWFileBinding.h"

@interface MPWDirectoryBinding : MPWFileBinding
{
    NSArray *contents;
    BOOL    fancy;
}

-(instancetype)initWithContents:(NSArray*)newContents;
-(NSArray*)contents;

@end
