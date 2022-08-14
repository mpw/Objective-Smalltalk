//
//  MPWScriptedMethod.h
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWMethodHeader;

@interface MPWScriptedMethod : MPWAbstractInterpretedMethod {
	id					script;
	MPWExpression*		methodBody;
	NSArray*			localVars;
	id					contextClass;
}

objectAccessor_h(MPWExpression*, methodBody, setMethodBody )
objectAccessor_h(NSArray*, localVars, setLocalVars )
idAccessor_h( script, setScript )

@property (nonatomic,assign) Class classOfMethod;


@end

@interface NSException(scriptStackTrace)

-(NSMutableArray*)scriptStackTrace;

objectAccessor_h(NSMutableArray*, combinedStackTrace, setCombinedStackTrace)
//-(NSMutableArray*)combinedStackTrace;
//-(void)setCombined
-(void)addCombinedFrame:(NSString*)frame frameToReplace:original previousTrace:previousTrace;
-(void)addScriptFrame:(NSString*)frame;


@end

