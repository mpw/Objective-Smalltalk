//
//  MPWClangImporter.h
//  MPWCSourceKit
//
//  Created by Marcel Weiher on 7/23/18.
//

#import <Foundation/Foundation.h>

@protocol CImporterDelegate

-(void)globalVariable:(NSString*)name type:(NSString*)type;
-(void)enumCase:(NSString*)name value:(long)value;


@end


@interface MPWClangImporter : NSObject <CImporterDelegate>

@end
