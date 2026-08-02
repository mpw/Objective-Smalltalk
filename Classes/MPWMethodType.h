//
//  MPWMethodType.h
//  psdb
//
//  Created by Marcel Weiher on 22/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


// NSObject, not MPWObject: shared across evaluation threads (see STExpression).
@interface MPWMethodType : NSObject {
	NSString*	typeName;
	NSString*	methodClassName;
}

+methodTypeWithName:(NSString*)name className:(NSString*)className;

//-(NSString*)name;
//-(NSString*)className;
-(NSString*)typeName;
-(Class)methodClass;

@end
