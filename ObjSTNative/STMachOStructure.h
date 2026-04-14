//
//  STMachOStructure.h
//  ObjSTNative
//
//  Created by Marcel Weiher on 14.04.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STMachOStructure : NSObject

@property (nonatomic, strong ) MPWStructureDefinition *definition;
@property (nonatomic, strong ) NSArray *values;

@end

NS_ASSUME_NONNULL_END
