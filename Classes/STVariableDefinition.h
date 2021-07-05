//
//  STVariableDefinition.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 01.07.21.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class STTypeDescriptor;

@interface STVariableDefinition : NSObject

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) STTypeDescriptor *type;

-initWithName:(NSString*)newName type:(STTypeDescriptor*)newType;


@end

NS_ASSUME_NONNULL_END
