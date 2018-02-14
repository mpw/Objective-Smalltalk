//
//  MPWSpotlightScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/13/18.
//

#import "MPWSpotlightScheme.h"
#import <CoreServices/CoreServices.h>
#import "MPWFileBinding.h"
#import "MPWDirectoryBinding.h"

@interface MPWSpotlightSearchBinding : MPWDirectoryBinding
{
    
}

@property (nonatomic,strong) NSMetadataQuery *query;
@property (nonatomic,strong) MPWGenericBinding *originalBinding;



@end
@implementation MPWSpotlightSearchBinding

-value
{
    NSMutableArray *contents=[NSMutableArray array];

    for ( NSMetadataItem *item in [[self.query.results copy] autorelease]  ) {
        NSString *path=[item valueForAttribute:(NSString*)kMDItemPath];
        MPWFileBinding *f=[[[MPWFileBinding alloc] initWithPath:path] autorelease];
        f.parentPath = [self name];
        [contents addObject:f];
    }
    return contents;
}

-(NSArray *)contents
{
    NSArray *c=[super contents];
    if (!c) {
        c=[self value];
    }
    return c;
}

-(BOOL)done
{
    return self.query.isStarted && !self.query.isGathering;
}


@end

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
        NSString *query=queryStrings[[queryItem name]];
        if ( query ) {
            NSPredicate *p=[NSPredicate predicateWithFormat:query,[queryItem value]];
            [predicates addObject:p];
        }
    }
    NSPredicate *p=nil;
    if (predicates.count){
        [q setPredicate:predicates.count==1 ? predicates.firstObject : [NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    }
    [q setSearchScopes:@[ components.path ]];
    [q setOperationQueue:[[NSOperationQueue new] autorelease]];
    MPWSpotlightSearchBinding *sb=[MPWSpotlightSearchBinding bindingWithName:components.path scheme:self];
    sb.originalBinding=aBinding;
    sb.query=q;
    [sb.query startQuery];
    return sb;
}


@end
