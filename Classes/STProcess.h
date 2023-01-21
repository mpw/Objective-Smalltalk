//
//  STProcess.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 16.01.23.
//

#import <Foundation/Foundation.h>


@interface NSObject(stprocess)

-main:args;
-Stdout;
+(int)main:(NSArray <NSString*>*)args;
+(int)mainArgc:(int)argc argv:(char**)argv;

@end



@interface STProcess : NSObject


@end

