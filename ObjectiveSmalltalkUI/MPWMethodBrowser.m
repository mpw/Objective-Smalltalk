//
//  VBMethodBrowser.m
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 23.01.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import "MPWMethodBrowser.h"
#import <MPWFoundation/MPWFoundation.h>
#import <ObjectiveSmalltalk/MPWMethodHeader.h>
#import "MPWClassMethodSwitchStore.h"


@interface MPWMethodBrowser ()

@property (nonatomic,strong) MPWClassMethodSwitchStore* mappedStore;
@property (nonatomic,strong) id <MPWStorage> baseStore;

@end

@implementation MPWMethodBrowser


-(instancetype)initWithDefaultNib
{
    return [self initWithNibName:@"MPWMethodBrowser" bundle:[NSBundle bundleForClass:[self class]]];
}


-(void)setUIForMethodHeader:(NSString*)header body:(NSString*)body
{
    [[self methodHeader] setStringValue:header];
    [[self methodBody] setString:body];
}

-(void)clearMethodFromUI
{
    [self setUIForMethodHeader:@"" body:@""];
}

-(void)loadMethodFromPath:(id <MPWReferencing>)ref
{
    if ( [self isReferencingMethod:ref]) {
        NSString *methodBodyString=self.mappedStore[ref];
        NSString *methodName=ref.pathComponents.lastObject;
        [self setUIForMethodHeader:methodName body:methodBodyString];
    } else {
        [self clearMethodFromUI];
    }
}

-(id <MPWReferencing>)selectedReference
{
    return methodBrowser.currentReference;
}

-(IBAction)didSelect:(MPWBrowser*)sender
{
    [self loadMethodFromPath:sender.currentReference];
}

-(BOOL)showClassMethods
{
    return [[instanceClassSelector selectedCell] tag] == 2;
}

-(BOOL)isReferencingMethod:(id <MPWReferencing>)ref
{
    return ![self.mappedStore hasChildren:ref];
}

-(void)setMethodStore:(id<MPWStorage>)methodStore
{
    self.baseStore=methodStore;
    self.mappedStore=[MPWClassMethodSwitchStore storeWithSource: methodStore];
    methodBrowser.store=self.mappedStore;
}

-(id<MPWStorage>)methodStore
{
    return self.baseStore;
}

-(void)awakeFromNib
{
    NSLog(@"%@:%p awakeFromNib",[self class],self);
    [super awakeFromNib];
    [self.methodBody setAutomaticQuoteSubstitutionEnabled:NO];
    [self.methodBody setAutomaticLinkDetectionEnabled:NO];
    [self.methodBody setAutomaticDataDetectionEnabled:NO];
    [self.methodBody setAutomaticDashSubstitutionEnabled:NO];
    [self.methodBody setAutomaticTextReplacementEnabled:NO];
    [self.methodBody setAutomaticSpellingCorrectionEnabled:NO];
    [self.methodBody setFont:[NSFont fontWithName:@"Menlo Regular" size:11]];
    [self.methodHeader setFont:[NSFont fontWithName:@"Menlo Regular" size:12]];
    methodBrowser.store=self.mappedStore;
    [methodBrowser setBrowserDelegate:self];
    [methodBrowser loadColumnZero];
    NSLog(@"%@:%p awakeFromNib did initialize methodStore %@",[self class],self,methodBrowser.store);
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)display
{
    [methodBrowser loadColumnZero];
}

//---- browser delegate


- (id)browser:(MPWBrowser *)browser objectValueForItem:(id)item
{
    NSString *name = [[item relativePathComponents] lastObject];
    if ( [self isReferencingMethod:item]) {
        MPWMethodHeader *header=[MPWMethodHeader methodHeaderWithString:name];
        name = [header methodName];
    }
    return name;
}

-(NSString*)uiMethodBodyString
{
    return [[[self.methodBody string] copy] autorelease];
}


-(IBAction)saveMethodBody
{
    MPWGenericReference *ref=[self selectedReference];
    if ( [self isReferencingMethod:ref]) {
        self.mappedStore[ref]=[self uiMethodBodyString];
    }
}

//  TODO:  undo handling, should do as store


-(IBAction)delete:(MPWBrowser*)sender
{
    id <MPWReferencing> ref=[sender currentReference];
    if ( [self isReferencingMethod:ref]) {
        [self.mappedStore deleteObjectForReference:ref];
        [self clearMethodFromUI];
    } else {
        // delete a class
    }
    [self clearMethodFromUI];
}


-(void)textDidChange:(NSNotification *)notification {
    if ( self.continuous) {
        [self saveMethodBody];
    }
}



-(void)dealloc
{
    [_methodHeader release];
    [_methodBody release];
    [_mappedStore release];
    [super dealloc];
}

@end
