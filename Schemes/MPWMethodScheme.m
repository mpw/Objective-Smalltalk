//
//  MPWMethodScheme.m
//  Arch-S
//
//  Created by Marcel Weiher on 10/21/11.
//  Copyright (c) 2012 Marcel Weiher. All rights reserved.
//

#import "MPWMethodScheme.h"
#import "STCompiler.h"
#import "MPWMethodStore.h"
#import "MPWClassMirror.h"
#import "MPWScriptedMethod.h"

@implementation MPWMethodScheme


objectAccessor(STCompiler*, interpreter, setInterpreter )
objectAccessor(NSMutableArray*, exceptions, setExceptions)

-initWithInterpreter:anInterpreter
{
    self = [super init];
    [self setInterpreter:anInterpreter];
    [self setExceptions:[NSMutableArray arrayWithCapacity:20]];
    return self;
}


-(MPWMethodStore*)methodStore
{
    return [[self interpreter] methodStore];
}

-(NSArray*)methodList
{
    return [[self  methodStore] classesWithScripts];
}


-eval:(NSString*)aString
{
    NSLog(@"MPWMethodScheme will eval: %@",aString);
    id result=@"";
    @try {
        result = [[self interpreter] evaluateScriptString:aString];
    } @catch ( id e ) {
        NSLog(@"evaluating '%@' threw '%@'",aString,e);
        result=[e description];
    }
//    NSLog(@"%@ result: %@",[self class],result);
    
    return [result asData];
}

//-methodsForPath:(NSArray*)components
//{
//    if ( [components count] > 0 ) {
//        NSDictionary *methodDict=[[self methodStore] methodDictionaryForClassNamed:[components objectAtIndex:0]];
//        if ( [components count] == 1 ) {
//            return [methodDict allKeys];
//        } else   if ( [components count] == 2 ){
//            return [methodDict objectForKey:[components objectAtIndex:1]];
//        } else {
//            return nil;
//        }
//    }
//    else {
//        return [[self methodStore] externalScriptDict];
//    }
//}

-(NSArray*)allClasses
{
    NSArray *allClassNames = (NSArray*)[[[MPWClassMirror allClasses] collect] name];
//    allClassNames=[[[NSBundle mainBundle] selectArg:2] classNamed:[allClassNames each]];
    
    return [allClassNames sortedArrayUsingSelector:@selector(compare:)];
}

-contentForPath:(NSArray*)components
{
    if ( [components count] > 0 ) {
        NSString *first=[components objectAtIndex:0];
        if ( [first isEqual:@"classes"] ) {
            return [self methodList];
        } else if ( [first isEqual:@"allclasses"] ) {
                return [self allClasses];
//        } else if ( [first isEqual:@"methods"] ) {
//            return [self methodsForPath:[components subarrayWithRange:NSMakeRange(1, [components count]-1)]];
//        } else if ( [first isEqual:@"theAnswer"] ) {
//            return [[NSString stringWithFormat:@"the answer: %d",[self theAnswer]] asData];
        } else if ( [first isEqual:@"bundles"] ) {
            return [[[[[NSBundle allBundles] collect] bundleIdentifier] description] asData];
        } else if ( [first isEqual:@"exception"] ) {
            NSLog(@"%d exceptions",(int)[[self exceptions] count]);
            if ( [self hasExceptions]) {
                NSMutableArray *plist=[NSMutableArray array];
                for ( NSException *e in [self exceptions] ) {
                    NSArray *stackTrace=[e combinedStackTrace];
                    if ( !stackTrace ) {
                        stackTrace=[e scriptStackTrace];
                    }
                    [plist addObject:@{
                            @"name" : [e name] ?: @"NO Name",
                            @"reason": [e reason] ?: @"NO reason",
                            @"userInfo": [e userInfo] ?: @"NO USERINFO",
                            @"stack": stackTrace ?: @"NO stackTrace",
                        }
                     ];
                }
                
                
                return [NSClassFromString(@"NSJSONSerialization") dataWithJSONObject:plist options:0 error:nil];
            } else {
                return [@"NONE" asData];
            }
        } else if ( [first isEqual:@"allClasses"] ) {
            NSString *whichClasses=[components lastObject];
            NSArray *classes=[MPWClassMirror allUsefulClasses];
            if ([whichClasses isEqualToString:@"all"] ||
                [whichClasses isEqualToString:@"allClasses"] ) {
                ;   // already have all classes
            } else  {
                NSBundle *bundleToCheck=nil;
                if ( [whichClasses isEqualToString:@"main"] ) {
                    bundleToCheck=[NSBundle mainBundle];
                } else {
                    bundleToCheck=[NSBundle bundleWithIdentifier:whichClasses];
                }
                NSMutableArray *bundleFilteredClasses=[NSMutableArray array];
                for ( MPWClassMirror *mirror in classes ) {
                    if ( [NSBundle bundleForClass:[mirror theClass]] == bundleToCheck ) {
                        [bundleFilteredClasses addObject:mirror];
                    }
                    
                }
                classes=bundleFilteredClasses;
            }
            return [[[[classes collect] name] description] asData];
        } else if ( [first isEqual:@"frameworks"] ) {
            return [[[(NSArray*)[[[NSBundle allFrameworks] collect] bundleIdentifier] sortedArrayUsingSelector:@selector(compare:)] description] asData];
        }
    }
    return [[components componentsJoinedByString:@"/"] asData];
}


-(id)at:(MPWGenericReference*)aReference
{
    return [self contentForPath:[aReference relativePathComponents]];
}


-(void)put:newValue at:(MPWGenericReference*)aReference
{
    NSString *uri=[aReference path];
//    NSLog(@"setValue to %@",uri);
    if ( [uri hasPrefix:@"methods"] ) {
        [self defineMethodsInExternalDict:newValue];
        return ;
//    } else  if ( [uri hasPrefix:@"/complete"] ) {
//        NSLog(@"completions for %@",[newValue stringValue]);
//        NSArray *completions=[interpreter completionsForString:[newValue stringValue]];
//        NSLog(@"completions: %@",completions);
    } else  if ( [uri hasPrefix:@"/eval"] ) {
        NSString *evalString = [newValue stringValue];
//        NSLog(@"should eval: %@",evalString);
        [self performSelectorOnMainThread:@selector(eval:) withObject:evalString waitUntilDone:YES];
        return ;
    }
}

-(void)addException:(NSException*)exception
{
    NSLog(@"top level exception: %@",exception);
    if ( [exception combinedStackTrace]) {
        NSLog(@"%@",[exception combinedStackTrace]);
    }
    [exceptions addObject:exception];
    NSLog(@"now have %ld exceptions",(long)[[self exceptions] count]);
}

-(void)clearExceptions
{
    [[self exceptions] removeAllObjects];
}

-(BOOL)hasExceptions
{
    return [[self exceptions] count]!=0;
}


-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
//    NSLog(@"scheme -- define methods: %@",dict);
    [self clearExceptions];
    if ( dict ) {
        [[self interpreter] defineMethodsInExternalDict:dict];
    }
}

-(void)dealloc
{
    [interpreter release];
    [exceptions release];
    [super dealloc];
}

@end
