//
//  MPWBlockExpression.h
//  Arch-S
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWExpression.h>


@interface MPWBlockExpression : MPWExpression {
	NSArray* statements;
	NSArray* declaredArguments;
}

+blockWithStatements:newStatements arguments:newArgs;

-(NSArray*)arguments;
-statementArray;

//   for the native compiler

@property (nonatomic, strong ) NSString *symbol;    // the block object symbol for static blocks 
@property (nonatomic, assign ) int  stackOffset;    // for ARM native compiler
@property (nonatomic, strong ) NSString *blockDescriptorSymbol;
@property (nonatomic, strong ) NSString *blockFunctionSymbol;

@end
