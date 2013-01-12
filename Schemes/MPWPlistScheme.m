//
//  MPWPlistScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 7/6/12.
//
//

#import "MPWPlistScheme.h"
#import "MPWGenericBinding.h"

@implementation MPWPlistScheme

idAccessor(plist, setPlist)

-localVarsForContext:aContext
{
    return plist;
}




@end
