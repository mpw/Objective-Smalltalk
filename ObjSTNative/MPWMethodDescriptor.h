//
//  MPWMethodDescriptor.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/21/14.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWMethodDescriptor : NSObject
{
    NSString *symbol;
    NSString *name;
    NSString *objcType;
}

objectAccessor_h(NSString*, symbol, setSymbol)
objectAccessor_h(NSString*, name, setName)
objectAccessor_h(NSString*, objcType, setObjcType)

@end
