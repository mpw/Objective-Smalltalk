//
//  MPWAssignmentExpression.h
//  Arch-S
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STExpression.h>

@class MPWIdentifierExpression;

@interface MPWAssignmentExpression : STExpression {
	MPWIdentifierExpression* lhs;
	id context;
	STExpression* rhs;
}

idAccessor_h( lhs, setLhs )
idAccessor_h( rhs, setRhs )

@end
