//
//  MPWLLVMCompiler.h
//  MPWTalk
//
//  Created by Marcel Weiher on 17/8/06.
//  Copyright 2006 Marcel Weiher. All rights reserved.
//

#import <MPWTalk/MPWEvaluator.h>


@interface MPWLLVMCompiler : MPWEvaluator {
	id	llvmMethod;
	id	methodHeader;
}

idAccessor_h( methodHeader, setMethodHeader )


@end
