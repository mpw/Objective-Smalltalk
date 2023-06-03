//
//  MPWPropertyPath.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 8/6/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing;

@interface MPWReferenceTemplate : NSObject

@property (nonatomic, strong) NSArray *pathComponents;
@property (readonly) NSString *name;
@property (readonly) NSArray *formalParameters;

+(instancetype)propertyPathWithReference:(id <MPWReferencing>)ref;
-(instancetype)initWithReference:(id <MPWReferencing>)ref;

-(NSDictionary*)bindingsForMatchedReference:(id <MPWReferencing>)ref;

@end
