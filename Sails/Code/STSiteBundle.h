//
//  STSiteBundle.h
//  SiteBuilding
//
//  Created by Marcel Weiher on 03.08.20.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@class STSiteServer;

@interface STSiteBundle : STBundle

-(void)startWebServerOnPort:(int)port;
-(void)setupSite;
-(void)runSite:(int)port;


@property (readonly) STSiteServer *siteServer;
@property (readonly) id renderer;

@end

NS_ASSUME_NONNULL_END
