//
//  SailsGenerator.h
//  Sails
//
//  Created by Marcel Weiher on 01.01.24.
//

#import <Foundation/Foundation.h>

@class STSiteBundle;

NS_ASSUME_NONNULL_BEGIN

@interface SailsGenerator : NSObject

@property (nonatomic,strong) NSString *path;
@property (readonly) STSiteBundle *bundle;

-(void)makeSiteOfType:(NSString*)siteType;

-(BOOL)generate;


@end

NS_ASSUME_NONNULL_END
