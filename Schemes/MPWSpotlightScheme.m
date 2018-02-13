//
//  MPWSpotlightScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/13/18.
//

#import "MPWSpotlightScheme.h"
#import <CoreServices/CoreServices.h>





@implementation MPWSpotlightScheme



-valueForBinding:aBinding
{
    NSDictionary *queryStrings=@{
                             @"type": @"kMDItemContentTypeTree == %@",
                             @"content": @"kMDItemTextContent CONTAINS %@",

    };
    NSURLComponents *components = [NSURLComponents componentsWithString:[aBinding path]];
    NSMetadataQuery *q = [[NSMetadataQuery new] autorelease];
    if ( [components path]) {
        [q setSearchScopes:@[ [components path]]];
    }
    NSMutableArray *predicates = [NSMutableArray array];
    for ( NSURLQueryItem* queryItem in [components queryItems])  {
        NSString *key=[queryItem name];
        NSString *value=[queryItem value];
        NSString *query=queryStrings[key];
         NSPredicate *p=[NSPredicate predicateWithFormat:query,value];
        [predicates addObject:p];
    }
    [q setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    [q setOperationQueue:[[NSOperationQueue new] autorelease]];
    [q startQuery];
    return q;
}


@end
