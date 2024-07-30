//
//  STPopUpButton.m
//  ObjectiveSmalltalkUI
//
//  Created by Marcel Weiher on 22.09.23.
//

#import "STPopUpButton.h"

@implementation STPopUpButton

-(instancetype)initWithDictionary:(NSDictionary *)dict ignoringKeys:(NSSet*)ignoredKeys
{
    BOOL pullsDown=NO;
    NSRect frameRect=NSZeroRect;
    id frameObject=dict[@"frame"];
    if ( frameObject ) {
        frameRect=[[frameObject asRect] rectValue];
    }
    NSNumber* pullsDownValue=dict[@"pullsDown"];
    if ( pullsDownValue ) {
        pullsDown = pullsDownValue.boolValue;
    }

    self=[self initWithFrame:frameRect pullsDown:pullsDown];
    NSSet *allIgnored=[ignoredKeys setByAddingObjectsFromSet:[NSSet setWithObjects:@"frame",@"items",@"pullsDown", nil]];
    for ( NSString *key in [dict allKeys]) {
        if ( ![allIgnored containsObject:key] ) {
            [self setValue:dict[key] forKey:key];
        }
    }
    id items = dict[@"items"];
    for (NSString* item in items) {
        [self addItemWithTitle:item];
    }
    
    return self;
}

-(BOOL)matchesRef:(id <MPWIdentifying>)ref
{
    return YES;
}

-(void)modelDidChange:(NSNotification*)notification
{
    [self updateFromRef];
}

-(void)updateFromRef
{
    if ( self.ref && !self.inProcessing) {
        self.objectValue = self.ref.value;
    }
    if ( self.enabledRef && !self.inProcessing) {
        self.enabled = [self.enabledRef.value boolValue];
    }
}

-(void)updateToRef
{
    if (self.ref) {
        self.ref.value = self.objectValue;
    }
}

-(void)setBinding:(MPWBinding*)newBinding
{
    self.ref = newBinding;
    self.target = self;
    self.action = @selector(updateToRef);
}


@end
