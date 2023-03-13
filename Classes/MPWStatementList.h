//
//  MPWStatementList.h
//  Arch-S
//
//  Created by Marcel Weiher on 11/22/04.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STExpression.h>


@interface MPWStatementList : STExpression {
	id statements;
}

objectAccessor_h( NSMutableArray*, statements, setStatements )

-(void)addStatement:aStatement;
+statementList;

@end
