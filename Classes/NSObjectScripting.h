//
//  NSObjectScripting.h
//  MPWTalk
//
//  Created by Marcel Weiher on 25/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject(stScripting)
+(BOOL)createSubclassWithName:(NSString*)className instanceVariables:(NSString*)varsAsString;
+(BOOL)createSubclassWithName:(NSString*)className;
+instanceVariables;
+ivarForName:(NSString*)name;
+(void)generateAccessorsFor:(NSString*)varName;
-evaluateScript:(NSString*)scriptString;


@end
