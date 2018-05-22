//
//  MPWSelfContainedBinding.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/18.
//

#import <MPWFoundation/MPWBinding.h>

@interface MPWSelfContainedBinding : NSObject<MPWBinding>

@property (nonatomic, strong)  id value;

+(instancetype)bindingWithValue:newValue;

@end
