//
//  STScriptedMethod.h
//  Arch-S
//
//  Created by Marcel Weiher on 12/09/2005.
//  Copyright 2005 Marcel Weiher. All rights reserved.
//

#import <ObjectiveSmalltalk/MPWAbstractInterpretedMethod.h>

@class MPWMethodHeader,MPWBlockExpression,STJittableData;

@interface STScriptedMethod : MPWAbstractInterpretedMethod {
	id					script;
	STExpression*		methodBody;
    NSArray*			localVars;
	id					contextClass;
}

objectAccessor_h(STExpression*, methodBody, setMethodBody )
objectAccessor_h(NSArray*, localVars, setLocalVars )
@property (readonly, nonatomic) NSArray <MPWBlockExpression*>* blocks;
idAccessor_h( script, setScript )

@property (nonatomic,assign) Class classOfMethod;
@property (nonatomic, strong) STJittableData *nativeCode;

-(void)installNativeCode;
-(BOOL)isNativeCodeActive;

@end

@interface NSException(scriptStackTrace)

-(NSMutableArray*)scriptStackTrace;

objectAccessor_h(NSMutableArray*, combinedStackTrace, setCombinedStackTrace)
//-(NSMutableArray*)combinedStackTrace;
//-(void)setCombined
-(void)addCombinedFrame:(NSString*)frame frameToReplace:original previousTrace:previousTrace;
-(void)addScriptFrame:(NSString*)frame;


@end

