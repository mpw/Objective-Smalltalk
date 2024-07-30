//
//  MPWSpotlightScheme.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/13/18.
//

#import <ObjectiveSmalltalk/MPWSpotlightScheme.h>
#import <CoreServices/CoreServices.h>
#import <MPWFoundation/MPWFoundation.h>

@interface MPWSpotlightSearchBinding : MPWDirectoryReference
{
    
}

@property (nonatomic,strong) NSMetadataQuery *query;
@property (nonatomic,strong) MPWGenericIdentifier *originalReference;



@end
@implementation MPWSpotlightSearchBinding

-value
{
    NSMutableArray *contents=[NSMutableArray array];

    for ( NSMetadataItem *item in [[self.query.results copy] autorelease]  ) {
        NSString *path=[item valueForAttribute:(NSString*)kMDItemPath];
        MPWFileReference *f=[[[MPWFileReference alloc] initWithPath:path] autorelease];
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


-(id)at:(MPWGenericIdentifier*)aReference
{
    NSDictionary *queryStrings=@{
                             @"type": @"kMDItemContentTypeTree == %@",
                             @"content": @"kMDItemTextContent CONTAINS %@",

    };
    NSURLComponents *components = [NSURLComponents componentsWithString:[aReference path]];
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
    if (predicates.count){
        [q setPredicate:predicates.count==1 ? predicates.firstObject : [NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    }
    [q setSearchScopes:@[ components.path ]];
    [q setOperationQueue:[[NSOperationQueue new] autorelease]];
    MPWSpotlightSearchBinding *sb=[[MPWSpotlightSearchBinding new] autorelease];
    sb.store = self;
    sb.originalReference=aReference;
    sb.query=q;
    [sb.query startQuery];
    return sb;
}


@end
