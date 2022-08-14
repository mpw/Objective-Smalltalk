//
//  ViewController.m
//  UIViewBuilderMockup
//
//  Created by Marcel Weiher on 09.01.21.
//  Copyright © 2021 Marcel Weiher. All rights reserved.
//

#import "UIViewBuilderSmalltalkViewController.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>
#import <MPWFoundation/MPWFoundation.h>

@interface UIImageFromData : MPWMappingStore
@end

@implementation UIImageFromData

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    NSLog(@"mapRetrievedObject: %@ forReference: %@",anObject,aReference);
    anObject = [anObject performSelector:@selector(TIFFRepresentation)];
    return [UIImage imageWithData:anObject];
}

@end


@interface UIViewBuilderSmalltalkViewController ()

@property (nonatomic,strong) STCompiler *compiler;
@property (nonatomic, strong) MPWByteStream  *consoleStream;
@property (nonatomic, strong) NSString *programText;
@end

@implementation UIViewBuilderSmalltalkViewController
{
    MPWByteStream *consoleStream;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self=[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [self installProtocolNotifications];
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];
    [self installProtocolNotifications];
    return self;
}

lazyAccessor( MPWByteStream*, consoleStream, setConsoleStream, createConsoleStream)

-(MPWByteStream*)createConsoleStream
{
    return [MPWByteStream streamWithTarget:[[self.log textStorage] mutableString]];
}

-(NSDictionary*)deseralize:(NSString*)name
{
    NSData *data=[self frameworkResource:@"UIKitEnums" category:@"json"];
    NSDictionary *dict=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return dict;
}

-(void)writeObject:(NSDictionary*)userInfo
{
    NSData *script=userInfo[@"ProgramText"];
    NSString *resourceURIString=userInfo[@"Resources"];
    MPWURLSchemeResolver *resourceLoader = [MPWPathRelativeStore storeWithSource:[MPWURLSchemeResolver store] reference:[MPWGenericReference referenceWithPath:resourceURIString]];
    UIImageFromData *mapper = [UIImageFromData storeWithSource:resourceLoader];
    [self.compiler bindValue:mapper toVariableNamed:@"imageMapper"];
    [self.compiler bindValue:resourceLoader toVariableNamed:@"resourceLoader"];
    [self.compiler evaluateScriptString:@"scheme:img := imageMapper."];
    [self.compiler evaluateScriptString:@"scheme:rsrc := resourceLoader."];
    self.programText = [script stringValue];
    [self evaluate];
}

-(void)evaluateNewCode:(NSNotification*)notification
{
    NSLog(@"evaluateNewCode:");
    [self writeObject:notification.userInfo];
}


- (void)viewDidLoad {
    self.compiler=[STCompiler compiler];
    STCompiler *compiler=self.compiler;
    MPWGlobalVariableStore *globals=[MPWGlobalVariableStore store];
    NSDictionary *enums=[self deseralize:@"UIKitEnums"];
    NSString *init= [[self frameworkResource:@"UIKitInit" category:@"st"] stringValue];
    [self.compiler bindValue:enums toVariableNamed:@"allEnums"];
    [self.compiler bindValue:globals toVariableNamed:@"globalLookup"];
    [self.compiler bindValue:[MPWDictStore storeWithDictionary:  (NSMutableDictionary*)enums] toVariableNamed:@"enumsScheme"];
    
    NSObject <MPWStorage,MPWHierarchicalStorage> *builder = [compiler schemeForName:@"builder"];
    NSDictionary *map = @{
        @"Label": @"UILabel",
        @"Stack": @"UIStackView",
        @"Image": @"UIImageView",
        @"Field": @"UITextField",
    };
    MPWNameRemappingStore *s = [MPWNameRemappingStore storeWithSource:builder];
    s.nameMap = map;
    [compiler bindValue:s toVariableNamed:@"builderMapper"];
    [compiler evaluateScriptString:@" scheme:builder := builderMapper. "];
    [compiler evaluateScriptString:@" scheme:c := enumsScheme. "];
    [compiler evaluateScriptString:@" scheme:g := globalLookup. "];
    [compiler evaluateScriptString:@" scheme:color := MPWColorStore store. "];
    [compiler evaluateScriptString:@" scheme:font := MPWFontStore store. "];

    [compiler evaluateScriptString:init];
//    [self.compiler evaluateScriptString:@" scheme:default := MPWSequentialStore storeWithStores: #( scheme:var, enumsScheme ). "];

    NSLog(@"3+4=%@",[self.compiler evaluateScriptString:@"3+4"]);
    [super viewDidLoad];

    [self evaluate];
}


-(void)evaluate
{
    [self.log.textStorage replaceCharactersInRange:NSMakeRange(0,self.log.text.length) withString:@""];
    @try {
        [self.compiler bindValue:self.consoleStream toVariableNamed:@"stdout"];
        [self.compiler bindValue:self.preview toVariableNamed:@"preview"];
//        [self stashProgramTextInTmp];
        id result = [self.compiler evaluateScriptString:self.programText];
        if ( [result isKindOfClass:[UIView class]]) {
            UIView *resultView = result;
            [[[self.preview subviews] do] removeFromSuperview];
            
            if ( resultView.frame.size.width < 1 || resultView.frame.size.height < 1 ) {
                resultView.frame = self.preview.bounds;
//                resultView.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
            } else if ( resultView.frame.origin.x < 1 || resultView.frame.origin.y < 1) {
                NSRect resultFrame=resultView.frame;
                NSRect targetFrame=self.preview.frame;
                NSPoint offset = { (targetFrame.size.width - resultFrame.size.width)/2,
                    (targetFrame.size.height - resultFrame.size.height)/2};
                resultFrame.origin=offset;
                resultView.frame = resultFrame;
//                resultView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
            }

            
            [self.preview addSubview:resultView];
            [self.compiler evaluateScriptString:@"protocol:ModelDidChange notify."];
        } else {
            [[[self.preview subviews] do] removeFromSuperview];
            [self.consoleStream printFormat:@"%@\n",result];
        }
    } @catch ( id exception ){
        [self.log setTextColor:[UIColor redColor]];
        [self.consoleStream printFormat:@"error: %@\n",exception];
        [self.log setTextColor:[UIColor redColor]];
   }
}


@end

