//
//  MPWShellPrinter.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/14.
//
//

#import <MPWFoundation/MPWPropertyListStream.h>

@interface MPWShellPrinter : MPWPropertyListStream

-(void)printNames:(NSArray*)names limit:(int)completionLimit;


-(void)writeDirectory:(MPWDirectoryBinding*)aBinding;
-(void)writeFancyDirectory:(MPWDirectoryBinding*)aBinding;

@end
