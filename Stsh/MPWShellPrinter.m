//
//  MPWShellPrinter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/14.
//
//

#import "MPWShellPrinter.h"
#import "MPWDirectoryBinding.h"
#import <histedit.h>
#include <readline/readline.h>

@interface NSObject(shellPrinting)

-(void)writeOnShellPrinter:(MPWShellPrinter*)aPrinter;


@end


@implementation MPWShellPrinter

-(SEL)streamWriterMessage
{
    return @selector(writeOnShellPrinter:);
}


-(int)terminalWidth
{
    struct winsize w;
    ioctl(0, TIOCGWINSZ, &w);
    
    return w.ws_col;
}



-(void)printNames:(NSArray*)names limit:(int)completionLimit
{
    int numEntries=MIN(completionLimit,(int)[names count]);
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
                    int columnPad =columnWidth-(int)[theItem length];
                    columnPad=MIN(MAX(columnPad,0),columnWidth);
                    for (int sp=0;sp<columnPad;sp++) {
                        putc(' ', stderr);
                    }
                }
            }
        }
        putc('\n', stderr);
    }
}

-(void)writeDirectory:(MPWDirectoryBinding*)aBinding
{
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWFileBinding *binding in [aBinding contents]) {
        NSString *name=[(NSString*)[binding path] lastPathComponent];
        if ( ![name hasPrefix:@"."]) {
            [names addObject:name];
        }
    }
    [self printNames:names limit:1000];
}

@end

@implementation NSObject(shellPrinting)

-(void)writeOnShellPrinter:(MPWShellPrinter*)aPrinter
{
    [self writeOnPropertyList:aPrinter];
}

@end
