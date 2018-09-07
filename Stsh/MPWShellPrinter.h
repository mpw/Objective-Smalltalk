//
//  MPWShellPrinter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/14.
//
//

#import <MPWFoundation/MPWPropertyListStream.h>

@interface MPWShellPrinter : MPWPropertyListStream

@property (nonatomic, weak)  id environment;

-(void)printNames:(NSArray*)names limit:(int)completionLimit;


-(void)writeDirectory:aBinding;
-(void)writeFancyDirectory:aBinding;

@end
