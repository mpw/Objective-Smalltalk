//
//  SailsGenerator.h
//  Sails
//
//  Created by Marcel Weiher on 01.01.24.
//

#import <Foundation/Foundation.h>

@class STSiteBundle,STClassDefinition;

NS_ASSUME_NONNULL_BEGIN

@interface SailsGenerator : NSObject

@property (nonatomic,strong) NSString *path;
@property (readonly) STSiteBundle *bundle;

-(void)makeSiteOfType:(NSString*)siteType;
-(NSString*)createEntityCodeForClassDescription:(STClassDefinition*)def;
-(NSString*)makeEntityNamed:(NSString*)entityName superclassName:(nullable NSString*)superclassName ivarNames:(NSArray*)ivarnames;

-(BOOL)generate;


@end

NS_ASSUME_NONNULL_END
