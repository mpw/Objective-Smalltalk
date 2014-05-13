//
//  MPWStsh.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 26/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved


#import "MPWStsh.h"
#import <histedit.h>
#include <readline/readline.h>

#import <ObjectiveSmalltalk/MPWIdentifierExpression.h>
#import "MPWShellCompiler.h"
#import "MPWStScript.h"
#import "MPWObjectMirror.h"
#import "MPWClassMirror.h"
#import "MPWMethodMirror.h"
#import "MPWMessageExpression.h"
#import "MPWAssignmentExpression.h"
#import "MPWStatementList.h"
#import <MPWFoundation/NSNil.h>
#import "MPWScheme.h"
#import <MPWFoundation/MPWByteStream.h>
#import "MPWAbstractShellCommand.h"
#import "MPWScriptedMethod.h"
#import "MPWExpression+autocomplete.h"



@interface NSObject(AppKitShims)

+sharedApplication;

@end

@interface MPWStsh(autocomplete) <AutocompleteTarget>


@end



@implementation MPWStsh
{
    EditLine *currentLine;
}

boolAccessor( readingFile, _setReadingFile )
boolAccessor( echo, setEcho )
idAccessor( _evaluator, _setEvaluator )
objectAccessor(NSString, prompt, _setPrompt)
intAccessor(completionLimit, setCompletionLimit)


-evaluator
{
	id eval=[self _evaluator];
	if ( !eval ) {
		eval=self;
	}
	return eval;
}


-(void)setPrompt:(NSString*)newPrompt
{
    [self _setPrompt:newPrompt];
    [newPrompt getCString:cstrPrompt maxLength:100 encoding:NSUTF8StringEncoding];
    cstrPrompt[100]=0;
}

-(void)setEvaluator:newEval
{
	[self _setEvaluator:newEval];
	[newEval bindValue:self toVariableNamed:@"shell"];
}
 

+(void)runCommand:commandName withArgs:args
{
	NSAutoreleasePool* pool=[NSAutoreleasePool new];
	MPWStsh* sh;
//	NSString* exprString = [NSString stringWithContentsOfFile:commandName encoding:NSUTF8StringEncoding error:nil];
	sh=[[[self alloc] initWithArgs:args] autorelease];
//	[sh bindValue:commandName toVariableNamed:@"commandName"];
	[sh setReadingFile:YES];
	[sh executeFromFileName:commandName];
//	expr = [sh compile:exprString];
//	[sh executeShellExpression:expr];
 	[pool release];
}

+(void)runWithArgs:(NSArray*)args
{
	NSAutoreleasePool* pool=[NSAutoreleasePool new];
	if ( [args count] >= 1 ) {
		[self runCommand:[args objectAtIndex:0] withArgs:[args subarrayWithRange:NSMakeRange(1,[args count]-1)]];
	} else {
		[[[[self alloc] init] autorelease] runInteractiveLoop];
	}
	[pool release];
}

+(void)runWithArgCount:(int)argc argStrings:(const char**)argv
{
	NSMutableArray *args=[NSMutableArray array];
	for (int i=1;i<argc;i++) {
		[args addObject:[NSString stringWithUTF8String:argv[i]]];
	}
    [self runWithArgs:args];
}

-(void)setReadingFile:(BOOL)newReadingFile
{
    [self _setReadingFile:newReadingFile];
    [self setEcho:!newReadingFile];
}


-(void)runAppKit
{
	[NSClassFromString(@"NSApplication") sharedApplication];
	[[self async] runInteractiveLoop];
	[[NSRunLoop currentRunLoop] run];
}

-initWithArgs:args evaluator:newEvaluator
{
    if ( self=[super init] ) {
//		NSLog(@"initWithArgs: %@",args);
        [self setPrompt:@"> "];
        Stdout=[MPWByteStream Stdout];
        Stderr=[MPWByteStream Stderr];
		[self setEvaluator:newEvaluator];
		[[self evaluator] bindValue:args toVariableNamed:@"args"];
		[[self evaluator] bindValue:self toVariableNamed:@"shell"];
        [self setCompletionLimit:120];
    }
    return self;
}

-initWithArgs:args
{
	return [self initWithArgs:args evaluator:[[[MPWShellCompiler alloc] init] autorelease]];
}


-init
{
	return [self initWithArgs:[NSArray array]];
}

-(const char*)getCStringPrompt
{
    return cstrPrompt;
}

static const char * promptfn(EditLine *e) {
    MPWStsh* self = nil;
    el_get(e, EL_CLIENTDATA,&self);
    const char *prompt="> ";
    if ( self ) {
        prompt=[self getCStringPrompt];
    }
    return prompt;
}

-(NSSet *)lessInterestingMessageNames
{
    static NSSet *lessInteresting=nil;
    if (!lessInteresting) {
        lessInteresting=[[NSSet alloc] initWithArray:
                @[
                  @"dealloc",
                  @"finalize",
                  @"copy",
                  @"copyWithZone:",
                  @"hash",
                  @"isEqual:",
                  @"release",
                  @"autorelease",
                  @"retain",
                  @"retainCount",
                  @"isKindOfClass:",
                  @"initWithCoder:",
                  @"encodeWithCoder:",
                  @"classForCoder",
                  @"valueForKey:",
                  @"takeValue:forKey:",
                  @"setValue:forKey",
                  @"self",
                  @"zone",
                ]];
    }
    return lessInteresting;
}

-(NSArray *)sortMessageNamesByImportance:(NSArray *)incomingMessageNames
{
    NSMutableArray *firstTier=[NSMutableArray array];
    NSMutableArray *secondTier=[NSMutableArray array];
    for ( NSString *messageName in incomingMessageNames) {
        if ( [messageName hasPrefix:@"_"] ||
             [messageName hasPrefix:@"accessibility"] || 
             [[self lessInterestingMessageNames] containsObject:messageName] )
        {
            [secondTier addObject:messageName];
        } else {
            [firstTier addObject:messageName];
        }
    }
    
    return [firstTier arrayByAddingObjectsFromArray:secondTier];
}

-(NSArray *)messageNamesForObject:value matchingPrefix:(NSString*)prefix
{
    NSMutableSet *alreadySeen=[NSMutableSet set];
    NSMutableArray *messages=[NSMutableArray array];
    MPWObjectMirror *om=[MPWObjectMirror mirrorWithObject:value] ;
    MPWClassMirror *cm=[om classMirror];
    while ( cm ){
        for (MPWMethodMirror *mm in [cm methodMirrors]) {
            NSString *methodName = [mm name];
            
            if ( (!prefix || [prefix length]==0 || [methodName hasPrefix:prefix]) &&
                ![alreadySeen containsObject:methodName]) {
                [messages addObject:methodName];
                [alreadySeen addObject:methodName];
            }
        }
        cm=[cm superclassMirror];
    }
    return [self sortMessageNamesByImportance:messages];
}

-(int)terminalWidth
{
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
        
    return w.ws_col;
}


-(void)printCompletions:(NSArray *)names
{
    int numEntries=MIN([self completionLimit],(int)[names count]);
    int numColumns=1;
    int terminalWidth=[self terminalWidth];
    int minSpacing=2;
    int maxWidth=0;
    int columnWidth=0;
    int numRows=0;
    for  (int i=0; i<numEntries;i++ ){
        if ( [names[i] length] > maxWidth ) {
            maxWidth=(int)[names[i] length];
        }
    }
    numColumns=terminalWidth / (maxWidth+minSpacing);
    numColumns=MAX(numColumns,1);
    columnWidth=terminalWidth/(numColumns);
    numRows=(numEntries+numColumns-1)/numColumns;
    

    for ( int i=0; i<numRows;i++ ){
        for (int j=0;j<numColumns;j++) {
            int theItemIndex=i*numColumns + j;
            
            if ( theItemIndex < [names count]) {
                NSString *theItem=names[theItemIndex];
                fprintf(stderr, "%.*s",columnWidth,[theItem UTF8String]);
                if (j<numColumns-1) {
                    int pad =columnWidth-(int)[theItem length];
                    pad=MIN(MAX(pad,0),columnWidth);
                    for (int sp=0;sp<pad;sp++) {
                        putc(' ', stderr);
                    }
                }
            }
        }
        putc('\n', stderr);
    }
}


-(NSArray *)schemesToCheck
{
    return @[ @"var", @"class", @"scheme"];
}

-(NSArray *)identifiersMatchingPrefix:(NSString*)prefix
{
    NSMutableArray *completions=[NSMutableArray array];
    for ( NSString *schemeName in [self schemesToCheck]) {
        [completions addObjectsFromArray:[[_evaluator schemeForName:schemeName] completionsForPartialName:prefix inContext:_evaluator]];
    }
    return completions;
}

-(NSString*)commonPrefixInNames:(NSArray*)names
{
    NSString *commonPrefix=[names firstObject];
    for ( NSString *name in names) {
        while ( ![name hasPrefix:commonPrefix] && [commonPrefix length]>0 ) {
            commonPrefix=[commonPrefix substringToIndex:[commonPrefix length]-1];
        }
        if ( [commonPrefix length]==0) {
            break;
        }
    }
    return  commonPrefix;
}

-(void)completeName:(NSString*)currentName withNames:(NSArray*)names
{
    NSString *commonPrefix=[self commonPrefixInNames:names];
    if ( [commonPrefix length] > [currentName length]) {
        NSString *completion=[commonPrefix substringFromIndex:[currentName length]];
//        NSLog(@"commonPrefix: %@ currentName: %@ completion: %@",commonPrefix,currentName,completion);
        [self insertStringIntoCurrentEditLine:completion];
    } else if ([names count]>1) {
        [self printCompletions:names];
    }
}


-(void)insertStringIntoCurrentEditLine:(NSString*)stringToInsert
{
    el_insertstr(currentLine, [stringToInsert UTF8String]);
}


-(BOOL)doCompletionWithLine:(EditLine*)e character:(char)ch
{
    currentLine=e;
    const LineInfo *lineInfo = el_line(e);
    if ( lineInfo) {
        const char *start=lineInfo->buffer;
        const char *end=lineInfo->lastchar;
        NSString *s=[[[NSString alloc] initWithBytes:start length:end-start encoding:NSUTF8StringEncoding] autorelease];

        MPWExpression *expr=nil;
        NSException *exception=nil;
        MPWStCompiler *evaluator=[self _evaluator];
        @try {
            fprintf(stderr, "\n");
            expr=[evaluator compile:s];
            return [expr completeString:s inShell:self];
        } @catch ( id e){
            exception=e;
        }
    }
    return NO;
}

static const char completionfun(EditLine *e, char ch) {
    MPWStsh* self = nil;
    el_get(e, EL_CLIENTDATA,&self);
    [self doCompletionWithLine:e character:ch];
    return CC_REDISPLAY;
}

-(void)cd:(NSString*)newDir
{
    long dirLen=[newDir length];
    dirLen=MIN(dirLen,10000);
    [newDir getCString:cwd maxLength:dirLen encoding:NSUTF8StringEncoding];
    cwd[ dirLen ] = 0;
    chdir(cwd);
}

-pwd
{
    return [NSString stringWithUTF8String:getwd( NULL )];
}




idAccessor( retval, setRetval )

-(void)executeFromFileName:(NSString*)filename
{
	id script = [MPWStScript scriptWithContentsOfFile:filename];
	[script executeInContext:self];
}

-(BOOL)isAssignmentExpresson:expr
{
	static Class MPWAssignmentExpression=nil;
	static Class MPWStatementList=nil;
	if ( !MPWStatementList ) {
		MPWAssignmentExpression=NSClassFromString(@"MPWAssignmentExpression");
		MPWStatementList=NSClassFromString(@"MPWStatementList");
	}
    return [expr isKindOfClass:MPWAssignmentExpression] 
		|| ([expr isKindOfClass:MPWStatementList] &&
			[[expr statements] count] == 1 &&
			[[[expr statements] lastObject] isKindOfClass:MPWAssignmentExpression]);
}

-(void)processShellEscape:(NSString*)exprString
{
    if ( [exprString hasPrefix:@"!cd"] ) {
        NSArray *components = [exprString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *last=nil;
        long index=[components count]-1;
        while (index>0 && [last length]==0) {
            last=[components objectAtIndex:index];
            index--;
        }
        const char *newDir = [last fileSystemRepresentation];
        if ( newDir) {
            int failure = chdir(newDir);
            if ( failure ) {
                perror("failed to chdir");
            }
        }
    } else {
        exprString=[@"source ~/.bashrc \n " stringByAppendingString:[exprString substringFromIndex:1]];
        system([exprString UTF8String]);
    }
}

-(void)runInteractiveLoop
{
    id result;
    EditLine *el;
    const char *lineOfInput;
    History *history_ptr;
    HistEvent event;
    int count=1000;
    history_ptr=history_init();
    el=el_init( "stsh", stdin, stdout, stderr);


    
    el_set(el, EL_CLIENTDATA, self);
    el_set( el, EL_HIST, history, history_ptr );
    el_set(el, EL_EDITOR, "emacs");
    el_set(el, EL_PROMPT, promptfn);
    el_set(el, EL_ADDFN, "complete", "complete", completionfun);
    el_set(el, EL_BIND, "\t", "complete", NULL);
    
    history(history_ptr, &event, H_SETSIZE, 800);
	[self setEcho:YES];
    NSMutableString *currentInput=[NSMutableString string];
    int level=1;
    
    while (  level > 0) {
        [self setPrompt:[NSString stringWithFormat:@"%@> ",level>1 ? @"*":@""]];
        lineOfInput=el_gets(el,&count);
        if ( !lineOfInput) {
            level--;
            [currentInput setString:@""];
            continue;
            
        }
        char *save;
 		if ( (lineOfInput[0]!='#') || (lineOfInput[1]=='(') ) {
			id pool=[NSAutoreleasePool new];
			NS_DURING
            NSString* newString = [NSString stringWithUTF8String:lineOfInput];
            [currentInput appendString:newString];
            NSString *exprString=currentInput;
            if ( level <=1 &&  [exprString hasPrefix:@"!"]) {
                [self processShellEscape:exprString];
                [currentInput setString:@""];
            }
            else {
                    id expr = nil;
                    @try {
                        expr = [[self evaluator] compile:exprString];
                        level=1;
                    } @catch ( NSException *exception) {
                        if ( [[exception userInfo][@"mightNeedMoreInput"] boolValue]) {
                            level=2;
                            continue;
                        }
                    }

                    [currentInput setString:@""];
                    BOOL isAssignment = [self isAssignmentExpresson:expr];
                    
                    if ( [[self evaluator] respondsToSelector:@selector(executeShellExpression:)] )  {
                        result = [[self evaluator] executeShellExpression:expr];
                    } else {
                        result = [[self evaluator] evaluate:expr];
                    }
                    //				NSLog(@"result: %@/%@",[result class],result);
                    if ( result!=nil && [result isNotNil]) {
                        [[self evaluator] bindValue:result toVariableNamed:@"last" withScheme:@"var"];
                        if ( [self echo] && !isAssignment ) {
                            //                       str_result = [[result description] cString];
                            //                       str_result = str_result ? str_result : "nil";
                            if ( !result ) {
                                result=@"nil";
                            }
                            fflush(stdout);
                            //						[[[MPWByteStream Stderr] do] println:[result each]];
                            //                        NSLog(@"result: %@/%@",[result class],result);
                            [(MPWByteStream*)[[[self evaluator] bindingForLocalVariableNamed:@"stdout" ]  value] println:[result stringValue]];
                            
                            
                            //                       fprintf(stderr,"%s\n",str_result);
                            fflush(stderr);
                        }
                    }
                }
            
            NS_HANDLER

            [(MPWByteStream*)[[[self evaluator] bindingForLocalVariableNamed:@"stderr" ]  value] println:localException];

            id combinedStack=[localException combinedStackTrace];
            if ( combinedStack) {
                [(MPWByteStream*)[[[self evaluator] bindingForLocalVariableNamed:@"stderr" ]  value] println:combinedStack];
            }
            NS_ENDHANDLER
			[pool release];
		}
        if ( strlen(lineOfInput) > 1) {
            save=malloc( strlen( lineOfInput) +2 );
            strcpy( save, lineOfInput );
            history( history_ptr, &event, H_ENTER, save );
            count=1000;
        }
    }
        fflush(stdout);
        fflush(stderr);
        fprintf(stderr,"\nBye!\n");
    exit(0);
}



@end

@implementation NSObject(executeInShell)

-executeInShell:aShell
{
    NSObject* result = [self evaluateIn:aShell];
//	NSLog(@"result of initial eval: %s, may no run process",object_getClassName(result));
	if ( [result isKindOfClass:[NSObject class]] && [result respondsToSelector:@selector(runProcess)] ) {
		result = [(MPWAbstractShellCommand*)result runProcess];
	}
	return result;
}

@end


@implementation MPWIdentifierExpression(executeInShell)

-executeInShell:aShell
{
	id level1result;
//	NSLog(@"%@ executeInShell:",self);
	level1result = [self evaluateIn:aShell];
// 	NSLog(@"level1result: %@ executeInShell:",level1result);
	return [level1result executeInShell:aShell]; 
}

@end


@implementation NSString(shellAdditions)

-initWithSingleUnichar:(int)character
{
	unichar uchar=character;
	return [self initWithCharacters:&uchar length:1];
}

+stringWithSingleUnichar:(int)character
{
	return [[[self alloc] initWithSingleUnichar:character] autorelease];
}

@end
