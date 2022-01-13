//
//  MPWCPUSimulator.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 11.01.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#define MEMSIZE 4096

@interface MPWCPUSimulator : NSObject
{
    unsigned long R[32];
    double FR[32];
    unsigned long M[MEMSIZE];
    
}

-(void)interpret:(int)start;

@end

NS_ASSUME_NONNULL_END
