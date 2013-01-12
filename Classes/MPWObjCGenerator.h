//
//  MPWObjCGenerator.h
//  MPWTalk
//
//  Created by Marcel Weiher on 15/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWObjCGenerator : MPWByteStream {

}

-(void)generateVariableWithName:aName;
-(void)writeMessage:selector toReceiver:receiver withArgs:args;
-(void)writeStatements:aList;


@end
