//
//  MPWGetAccessor.h
//  Arch-S
//
//  Created by Marcel Weiher on 21/07/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWInstanceVariable;

@interface MPWGetAccessor : MPWAbstractInterpretedMethod {
	MPWInstanceVariable* ivarDef;
}

+accessorForInstanceVariable:(MPWInstanceVariable*)ivarDef;

@end
