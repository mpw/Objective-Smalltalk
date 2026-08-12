//
//  MPWObjCGenerator.h
//  Arch-S
//
//  Created by Marcel Weiher on 15/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWLanguageGenerator.h>


@interface MPWObjCGenerator : MPWLanguageGenerator {

}

// The imports a generated Objective-Smalltalk compilation unit needs.
+(NSString*)standardImports;

-(void)generateVariableWithName:aName;
-(void)generateIdentifier:(id)identifier;
-(void)writeMessage:selector toReceiver:receiver withArgs:args;
-(void)writeMessage:selector toReceiver:receiver withArgs:args superSend:(BOOL)isSuperSend;
-(void)writeStatements:aList;
-(void)writeStatements:aList returningLast:(BOOL)returnLast;


@end
