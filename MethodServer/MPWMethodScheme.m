//
//  MPWMethodScheme.m
//  MPWTalk
//
//  Created by Marcel Weiher on 10/21/11.
//  Copyright (c) 2011 metaobject ltd. All rights reserved.
//

#import "MPWMethodScheme.h"
#import "MPWGenericBinding.h"
#import "MPWStCompiler.h"
#import "MPWMethodStore.h"

@implementation MPWMethodScheme

objectAccessor( MPWStCompiler , interpreter, setInterpreter )

-initWithInterpreter:anInterpreter
{
    self = [super init];
    [self setInterpreter:anInterpreter];
    return self;
}

-bindingForName:aName inContext:aContext
{
	if ( [aName hasPrefix:@"/"] ) {
		aName=[aName substringFromIndex:1];
	}
    return [super bindingForName:aName inContext:aContext];
}


-(MPWMethodStore*)methodStore
{
    return [[self interpreter] methodStore];
}

-(NSData*)methodList
{
    return [[self  methodStore] classesWithScripts];
}


-eval:(NSString*)aString
{
    id result=@"";
    @try {
        result = [[self interpreter] evaluateScriptString:aString];
    } @catch ( id e ) {
        NSLog(@"evaluating '%@' threw '%@'",aString,e);
    }
    NSLog(@"result: %@",result);
    
    return result;
}

-methodsForPath:(NSArray*)components
{
    if ( [components count] > 0 ) {
        NSDictionary *methodDict=[[self methodStore] methodDictionaryForClassNamed:[components objectAtIndex:0]];
        if ( [components count] == 1 ) {
            return [methodDict allKeys];
        } else   if ( [components count] == 2 ){
            return [methodDict objectForKey:[components objectAtIndex:1]];
        } else {
            return nil;
        }
    }
    else {
        return [[self methodStore] externalScriptDict];
    }
}

-contentForPath:(NSArray*)components
{
    if ( [components count] > 0 ) {
        NSString *first=[components objectAtIndex:0];
        if ( [first isEqual:@"classes"] ) {
            return [self methodList];
        } else if ( [first isEqual:@"methods"] ) {
            return [self methodsForPath:[components subarrayWithRange:NSMakeRange(1, [components count]-1)]];
        } else if ( [first isEqual:@"theAnswer"] ) {
            return [[NSString stringWithFormat:@"the answer: %d",[self theAnswer]] asData];
        }    
    }
    return [[components componentsJoinedByString:@"/"] asData];
}

-(void)setValue:newValue forBinding:(MPWGenericBinding*)aBinding
{
    NSString *uri=[aBinding name];
//    NSLog(@"setValue to %@",uri);
    if ( [uri hasPrefix:@"methods"] ) {
        [self defineMethodsInExternalDict:newValue];
        return ;
    } else  if ( [uri hasPrefix:@"/eval"] ) {
        NSString *evalString = [newValue stringValue];
//        NSLog(@"should eval: %@",evalString);
        [self performSelectorOnMainThread:@selector(eval:) withObject:evalString waitUntilDone:YES];
        return ;
    }
}

-(void)defineMethodsInExternalDict:(NSDictionary*)dict
{
//    NSLog(@"scheme -- define methods: %@",dict);
    if ( dict ) {
        [[self interpreter] defineMethodsInExternalDict:dict];
    }
}


@end
