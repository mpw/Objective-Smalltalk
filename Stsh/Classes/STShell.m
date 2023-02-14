//
//  MPWStsh.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 26/01/2006.
//  Copyright 2006 Marcel Weiher. All rights reserved


#import "STShell.h"
#import <histedit.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <unistd.h>

//#import <ObjectiveSmalltalk/MPWIdentifierExpression.h>
#import <ObjectiveSmalltalk/MPWStScanner.h>
#import "MPWShellCompiler.h"
#import "STScript.h"
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
#import "MPWShellPrinter.h"


@interface NSObject(AppKitShims)

+sharedApplication;

@end



@implementation STShell
{
    EditLine *currentLine;
}

boolAccessor( readingFile, _setReadingFile )
boolAccessor( echo, setEcho )
idAccessor( _evaluator, _setEvaluator )
objectAccessor(NSString*, prompt, _setPrompt)
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
    [newEval bindValue:[NSRunLoop currentRunLoop] toVariableNamed:@"runLoop"];
}
 

+(void)runCommand:commandName withArgs:args
{
    @autoreleasepool {
        STShell* sh;
        sh=[[[self alloc] initWithArgs:args] autorelease];
        [sh run];
    }
}

-(void)run
{
    if ( self.args.count == 0) {
        [self runInteractiveLoop];
    } else {
        self.commandName=self.args.firstObject;
        self.args = [self.args subarrayWithRange:NSMakeRange(1,[self.args count]-1)];
        [[self evaluator] bindValue:self.args toVariableNamed:@"args"];
        [self setReadingFile:YES];
        [self executeFromFileName:self.commandName];
    }
}

+(void)runWithArgs:(NSArray*)args
{
    @autoreleasepool {
        if ( [args count] >= 1 ) {
            [self runCommand:[args objectAtIndex:0] withArgs:[args subarrayWithRange:NSMakeRange(1,[args count]-1)]];
        } else {
            [[[[self alloc] init] autorelease] runInteractiveLoop];
        }
    }
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


-(void)runInRunLoop
{
    [[self async] runInteractiveLoop];
    runLoop=[NSRunLoop currentRunLoop];
    runLoopThread=[NSThread currentThread];
    [runLoop run];
}

-(void)runAppKit
{
    [NSClassFromString(@"NSApplication") sharedApplication];
    [self runInRunLoop];
}

-initWithArgs:args evaluator:newEvaluator
{
    if ( self=[super init] ) {
        self.args = args;
        self.evaluator = newEvaluator;
    
//		NSLog(@"initWithArgs: %@",args);
        BOOL istty=isatty(0);
//        NSLog(@"istty: %d",istty);
        if ( istty) {
            [self setPrompt:@"] "];
        }
        [self setReadingFile:!istty];
        Stdout=[MPWByteStream Stdout];
        Stderr=[MPWByteStream Stderr];
		[[self evaluator] bindValue:self toVariableNamed:@"shell"];
        [self setCompletionLimit:120];
        self.history = [NSMutableArray array];
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
    STShell* self = nil;
    el_get(e, EL_CLIENTDATA,&self);
    const char *prompt="] ";
    if ( self ) {
        prompt=[self getCStringPrompt];
    }
    return prompt;
}

-(void)printCompletions:(NSArray *)names
{
    [(MPWShellPrinter*)[[[self evaluator] bindingForLocalVariableNamed:@"stdout" ]  value] printNames:names limit:[self completionLimit]];
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
//    NSLog(@"completeName name '%@': %@",currentName,names);
    NSString *commonPrefix=[self commonPrefixInNames:names];
//    NSLog(@"common prefix '%@'",commonPrefix);
    if ( [commonPrefix length] > [currentName length]) {
        NSString *completion=[commonPrefix substringFromIndex:[currentName length]];
//        NSLog(@"commonPrefix: %@ currentName: %@ completion: %@",commonPrefix,currentName,completion);
        [self insertStringIntoCurrentEditLine:completion];
    } else if ([names count]>1) {
        [self printCompletions:names];
    } else if ([names count]==1) {
        [self insertStringIntoCurrentEditLine:[names firstObject]];
    } else {
    }
}


-(void)insertStringIntoCurrentEditLine:(NSString*)stringToInsert
{
    el_insertstr(currentLine, [stringToInsert UTF8String]);
}



-(BOOL)doCompletionWithLine:(EditLine*)e character:(char)ch
{
//    NSLog(@"doCompletionWithLine");
    currentLine=e;
    const LineInfo *lineInfo = el_line(e);
    if ( lineInfo) {
        const char *start=lineInfo->buffer;
        const char *end=lineInfo->lastchar;
        NSString *s=[[[NSString alloc] initWithBytes:start length:end-start encoding:NSUTF8StringEncoding] autorelease];

        MPWExpression *expr=nil;
        NSException *exception=nil;
        STCompiler *evaluator=[self _evaluator];
        @try {
            NSString *resultName=@"";
            fprintf(stderr, "\n");
            expr=[evaluator compile:s];
//            NSLog(@"will get completions for '%@'",s);
            NSArray *completions=[expr completionsForString:s withEvaluator:[self evaluator] resultName:&resultName];
//            NSLog(@"did get completions for '%@' -> %@",s,completions);
            [self completeName:resultName withNames:completions];
        } @catch ( id e){
//            NSLog(@"exception: %@",e);
            exception=e;
        }
    }
    return NO;
}

static const char completionfun(EditLine *e, char ch) {
    STShell* self = nil;
    el_get(e, EL_CLIENTDATA,&self);
    [self doCompletionWithLine:e character:ch];
    return CC_REDISPLAY;
}

-(void)cd:(NSString*)newDir
{
    @autoreleasepool {
        chdir([newDir fileSystemRepresentation]);
    }
}

-pwd
{
    char buf[MAXPATHLEN+1];
    return [NSString stringWithUTF8String:getcwd( buf , MAXPATHLEN )];
}




idAccessor( retval, setRetval )

-(void)executeFromFileName:(NSString*)filename
{
	id script = [STScript scriptWithContentsOfFile:filename];
    [[self evaluator] bindValue:filename toVariableNamed:@"argv0" withScheme:@"var"];
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

-(BOOL)isLiteral:expr
{
    return [expr isLiteral];
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

-(void)evaluateReturnValue:value
{
    [[[MPWByteStream Stdout] do] println:[value each]];
}


-(void)evaluateExpression:expr isAssignmnent:(BOOL)isAssignment
{
    id result=nil;
    @try {
        if ( [[self evaluator] respondsToSelector:@selector(executeShellExpression:)] )  {
            result = [[self evaluator] executeShellExpression:expr];
        } else {
            result = [[self evaluator] evaluate:expr];
        }
    } @catch ( NSException *localException ) {
        self.lastException=localException;
        fflush(stdout);
        return ;
    }
    //                NSLog(@"result: %@/%@",[result class],result);
    if ( result!=nil && [result isNotNil]) {
        [[self evaluator] bindValue:result toVariableNamed:@"last" withScheme:@"var"];
        
        if ( [self echo] && !isAssignment ) {
            //                       str_result = [[result description] cString];
            //                       str_result = str_result ? str_result : "nil";
            if ( !result ) {
                result=@"nil";
            }
            fflush(stdout);
            //                        [[[MPWByteStream Stderr] do] println:[result each]];
            //                        NSLog(@"result: %@/%@",[result class],result);
            MPWByteStream *myStdout=[[[self evaluator] bindingForLocalVariableNamed:@"stdout" ]  value];
            
            [myStdout writeObject:result];
            [myStdout writeNewline];
            
            
            //                       fprintf(stderr,"%s\n",str_result);
            fflush(stderr);
        }
    }
}

-(void)runInteractiveLoop
{
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
        [self setPrompt:[NSString stringWithFormat:@"%@] ",level>1 ? @"*":@""]];
        lineOfInput=el_gets(el,&count);
        if ( !lineOfInput) {
            level--;
            [currentInput setString:@""];
            continue;
            
        }
        char *save;
 		if ( (lineOfInput[0]!='#') || (lineOfInput[1]=='(') ) {
			id pool=[NSAutoreleasePool new];
            id expr = nil;
            NSString* newString = [NSString stringWithUTF8String:lineOfInput];
            [currentInput appendString:newString];
            NSString *exprString=currentInput;
            
            
            BOOL hasBangPrefix = [exprString hasPrefix:@"!"];
//            NSLog(@"hasBangPrexi: %d",hasBangPrefix);
            NSString *first = [[exprString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] firstObject];
            BOOL startsWithUnknownIdentifier=NO;
            if ( ![first containsString:@":"] && ![[self evaluator] bindingForLocalVariableNamed:first]) {
                startsWithUnknownIdentifier=YES;
            }
            @try {
                if ( !hasBangPrefix) {
                    expr = [[self evaluator] compile:exprString];
                    level=1;
                } else {

                }
            } @catch ( NSException *exception) {
//                NSLog(@"might need more input, exception: %@",exception);
                if ( [[exception userInfo][@"mightNeedMoreInput"] boolValue]) {
                    level=2;
                    continue;
                }
            }
            BOOL isAssignment = [self isAssignmentExpresson:expr];
            BOOL isLiteral = [self isLiteral:expr];
            if ( level <=1 &&  (hasBangPrefix || startsWithUnknownIdentifier) && !isAssignment && !isLiteral) {
//                exprString=[@"!" stringByAppendingString:exprString];
               [self processShellEscape:exprString];
                [currentInput setString:@""];
            }
            else {
                [currentInput setString:@""];
                self.lastException=nil;
				@try {
					if ( runLoopThread){
						[[self syncOnThread:runLoopThread] evaluateExpression:expr isAssignmnent:isAssignment];
					} else {
						[self evaluateExpression:expr isAssignmnent:isAssignment];
					}
				} @catch ( NSException *e) {
					if (!self.lastException) {
						self.lastException=e;
					} else {
						NSLog(@"exception trying to eval: %@",e);
					}
				}
            }
            
            if ( self.lastException) {
                [(MPWByteStream*)[[[self evaluator] bindingForLocalVariableNamed:@"stderr" ]  value] println:self.lastException];
                
                id combinedStack=[self.lastException combinedStackTrace];
                if ( combinedStack) {
                    [(MPWByteStream*)[[[self evaluator] bindingForLocalVariableNamed:@"stderr" ]  value] println:combinedStack];
                }
            }
            self.lastException=nil;
			[pool release];
		}
        if ( strlen(lineOfInput) > 1) {
            save=malloc( strlen( lineOfInput) +2 );
            strcpy( save, lineOfInput );
            history( history_ptr, &event, H_ENTER, save );
            count=1000;
            [self.history addObject:[NSString stringWithUTF8String:lineOfInput]];
        }
    }
    fflush(stdout);
    fflush(stderr);
    if ( ![self readingFile]) {
        fprintf(stderr,"\nBye!\n");
    }
//    exit(0);
}

-(void)writeHistoryOn:(MPWByteStream*)stream
{
    [stream printf:@"#!env %s\n",self.commandName.UTF8String];
    [[stream do] print:[self.history each]];
}

-(void)writeHistoryTo:(MPWFileBinding*)ref
{
    MPWByteStream *s=[ref writeStream];
    [self writeHistoryOn:s];
    [s close];
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
