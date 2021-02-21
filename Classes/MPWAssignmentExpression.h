//
//  MPWAssignmentExpression.h
//  MPWTalk
//
//  Created by marcel on Mon Jul 02 2001.
//  Copyright (c) 2001 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/STConnector.h>

@class MPWIdentifierExpression;

@interface MPWAssignmentExpression : STConnector {
	MPWIdentifierExpression* lhs;
	id context;
	MPWExpression* rhs;
}

idAccessor_h( lhs, setLhs )
idAccessor_h( rhs, setRhs )

@end
