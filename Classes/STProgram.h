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
+(int)intMain:(NSArray <NSString*>*)args;
+(int)mainArgc:(int)argc argv:(char**)argv;

@end



@interface STProgram : NSObject

@property (nonatomic,strong ) NSString *name;


@end

