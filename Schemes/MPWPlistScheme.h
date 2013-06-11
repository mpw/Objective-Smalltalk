//
//  MPWPlistScheme.h
//  MPWTalk
//
//  Created by Marcel Weiher on 7/6/12.
//
//

#import <ObjectiveSmalltalk/MPWVarScheme.h>

@interface MPWPlistScheme : MPWVarScheme
{
    id  plist;
}


-(void)setPlist:aPlist;

@end
