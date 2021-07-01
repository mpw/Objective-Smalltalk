//
//  STTypeDescriptor.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 30.06.21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    unsigned char objcTypeCode;
    char *name;
    char *cName;
} STTypeDescriptorStruct;


@interface STTypeDescriptor : NSObject

@property (nonatomic, assign, readonly) unsigned char objcTypeCode;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *cName;

@end

NS_ASSUME_NONNULL_END
