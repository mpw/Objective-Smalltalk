//
//  MPWShellPrinter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/14.
//
//

#import <MPWFoundation/MPWNeXTPListWriter.h>

@interface MPWShellPrinter : MPWNeXTPListWriter

@property (nonatomic, assign)  id environment;

-(void)printNames:(NSArray*)names limit:(int)completionLimit;

 
-(void)writeDirectory:aBinding;
-(void)writeFancyDirectory:aBinding;

@end
