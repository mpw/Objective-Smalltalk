//
//  MPWWindowsScheme.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 2/12/18.
//

#import "MPWWindowsScheme.h"
#import "MPWDirectoryBinding.h"

@implementation MPWWindowsScheme

-(NSArray*)windowList
{
    return (NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionAll ,  kCGNullWindowID);
}

-(NSArray*)appNameList
{
    NSMutableSet *appNames=[NSMutableSet set];
    for ( NSDictionary *d in [self windowList] ) {
        [appNames addObject:d[(NSString*)kCGWindowOwnerName]];
    }
    return [[appNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

-(NSArray*)appBindingsList
{
    return [[MPWGenericBinding collect] bindingWithName:[[self appNameList] each] scheme:self];
}


-(NSArray*)windowListForAppName:(NSString*)appName
{
    NSMutableSet *windowNames=[NSMutableSet set];
    for ( NSDictionary *d in [self windowList] ) {
        if ( [d[(NSString*)kCGWindowOwnerName] isEqualToString:appName]) {
            NSString *nameOrID=d[(NSString*)kCGWindowName];
            if ( !nameOrID) {
                nameOrID=[d[(NSString*)kCGWindowNumber] stringValue];
            }
            [windowNames addObject:nameOrID];
        }
    }
    NSArray *windowNameArray = [[windowNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
    return [[MPWGenericBinding collect] bindingWithName:[windowNameArray each] scheme:self];
}


-(NSArray*)windowNameNameListForAppName:(NSString*)appName andWindowName:(NSString*)windowName
{
    NSMutableSet *appNames=[NSMutableSet set];
    for ( NSDictionary *d in [self windowList] ) {
        [appNames addObject:d[(NSString*)kCGWindowOwnerName]];
    }
    return [[appNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

-(NSDictionary*)windowForAppName:(NSString*)appName andWindowName:(NSString*)windowName
{
    for ( NSDictionary *d in [self windowList] ) {
        if ( [d[(NSString*)kCGWindowOwnerName] isEqualToString:appName] &&
             ([d[(NSString*)kCGWindowName] isEqualToString:windowName] ||
              [[d[(NSString*)kCGWindowNumber] stringValue] isEqualToString:windowName])) {
                 return d;
             }
    }
    return nil;
}


-(NSBitmapImageRep*)screenshotForAppName:(NSString*)appName andWindowName:(NSString*)windowName
{
    NSDictionary *d=[self windowForAppName:appName andWindowName:windowName];
    NSNumber *windowNumber = d[(NSString*)kCGWindowNumber];
    CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, [windowNumber intValue], kCGWindowImageDefault);

    if ( windowImage) {
        NSBitmapImageRep *b=[[[NSBitmapImageRep alloc] initWithCGImage:windowImage] autorelease];
        [(id)windowImage release];
        return b;
    }
    return nil;
}

-valueForBinding:(MPWGenericBinding*)aBinding
{
    NSArray* resultArray=nil;

    NSString *path=[aBinding name];
    if ( [path isEqualToString:@"/"]) {
        path=@"";
    }
    NSArray *pathArray=[[aBinding name] componentsSeparatedByString:@"/"];
    if ( pathArray.count == 0 || pathArray.count==1 ) {
        resultArray = [self appBindingsList];
    } else if (pathArray.count==2  ) {
        NSString *appName=pathArray[1];
        resultArray = [self windowListForAppName:appName];
    } else if (pathArray.count==3  ) {
        return [self windowForAppName:pathArray[1] andWindowName:pathArray[2]];
    } else if (pathArray.count==4  ) {
        NSLog(@"last path: %@",pathArray.lastObject);
        if ( [pathArray.lastObject isEqualToString:@"screenshot"]) {
            NSLog(@"take screenshot");
            return [self screenshotForAppName:pathArray[1] andWindowName:pathArray[2]];
        } else {
            return [self windowForAppName:pathArray[1] andWindowName:pathArray[2]][pathArray.lastObject];
        }
    }
    if ( resultArray ) {
        MPWDirectoryBinding * result = [[[MPWDirectoryBinding alloc] initWithContents:resultArray] autorelease];
        return result;
    }
    return nil;
}


@end
