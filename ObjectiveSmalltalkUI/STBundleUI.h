//
//  STBundleUI.h
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 12.03.26.
//

#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SourceCodeChanged<MPWNotificationProtocol>
-(void)sourceCodeDidChange:sourceFile;
@end

@protocol ResourceChanged<MPWNotificationProtocol>
-(void)resourceDidChange:sourceFile;
@end



@class MPWFileBrowser;

@interface STBundle(UI)

-(MPWFileBrowser*)classBrowserLoggingTo:(id <Streaming>)logTarget;
-(MPWFileBrowser*)classBrowser;
-(MPWFileBrowser*)resourceBrowserLoggingTo:logToMe;
-(MPWFileBrowser*)resourceBrowser;


@end

NS_ASSUME_NONNULL_END
