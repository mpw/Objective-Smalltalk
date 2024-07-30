//
//  MPWSelfContainedBinding.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/18.
//

#import <MPWFoundation/MPWReference.h>

@interface MPWSelfContainedBinding : NSObject<MPWReferencing>

@property (nonatomic, strong)  id value;

+(instancetype)bindingWithValue:newValue;

@end
