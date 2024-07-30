//
//  MPWShellPrinter.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/22/14.
//
//

#import "MPWShellPrinter.h"
#import <MPWFoundation/MPWDirectoryReference.h>
#import <MPWFoundation/MPWFileReference.h>
#import <histedit.h>
#include <readline/readline.h>
 #include <sys/ioctl.h>

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
    int width = w.ws_col;
    if ( width == 0 ) {
        width=80;
    }
    return width;
}

-(int)numColumnsForTerminalWidth:(int)terminalWidth maxWidth:(int)maxWidth
{
    int minSpacing=2;
    int numColumns=terminalWidth / (maxWidth+minSpacing);
    numColumns=MAX(numColumns,1);
    return numColumns;
}

-(void)printNames:(NSArray*)names limit:(int)completionLimit
{
    int numEntries=MIN(completionLimit,(int)[names count]);
    int numColumns=1;
    int terminalWidth=[self terminalWidth];
    int maxWidth=0;
    int columnWidth=0;
    int numRows=0;
    for  (int i=0; i<numEntries;i++ ){
        if ( [names[i] length] > maxWidth ) {
            maxWidth=(int)[names[i] length];
        }
    }
    numColumns=[self numColumnsForTerminalWidth:terminalWidth maxWidth:maxWidth];
    columnWidth=terminalWidth/(numColumns);
    numRows=(numEntries+numColumns-1)/numColumns;
    
    
    for ( int i=0; i<numRows;i++ ){
        for (int j=0;j<numColumns;j++) {
            int theItemIndex=i*numColumns + j;
            
            if ( theItemIndex < [names count]) {
                NSString *theItem=names[theItemIndex];
//                NSLog(@"print: %@",theItem);
                [self printFormat:@"%.*s",columnWidth,[theItem UTF8String]];
                if (j<numColumns-1) {
                    int columnPad =columnWidth-(int)[theItem length];
                    columnPad=MIN(MAX(columnPad,0),columnWidth);
                    for (int sp=0;sp<columnPad;sp++) {
                        [self appendBytes:" " length:1];
                    }
                }
            }
        }
        if ( i<numRows-1) {
            [self println:@""];
        }
    }
    [self println:@""];
}

#ifdef GS_API_LATEST
-(NSString*)formattedFileSize:(long)filesize
{
    return [NSString stringWithFormat:@"%ld",filesize];
}
#else
-(NSString*)formattedFileSize:(long)filesize
{
    NSString *formattedSize=[NSByteCountFormatter stringFromByteCount:filesize countStyle:NSByteCountFormatterCountStyleBinary /* NSByteCountFormatterCountStyleFile */];
    return formattedSize;
}
#endif

-(void)writeFancyFileEntry:(MPWFileReference*)binding
{
    NSString *name=[binding fancyPath];
    if ( ![name hasPrefix:@"."]) {
        NSNumber *size=[binding fileSize];
        NSString *formattedSize=[self formattedFileSize:[size longValue]];
        formattedSize=[formattedSize stringByReplacingOccurrencesOfString:@" bytes" withString:@"  B"];
        int numSpaces=10-(int)[formattedSize length];
        numSpaces=MAX(0,numSpaces);
        NSString *spaces=[@"               " substringToIndex:numSpaces];
        [self printFormat:@"%@%@  %@%c\n",spaces,formattedSize,name,[binding hasChildren] ? '/':' '];
    }
}

-(void)writeDirectory:(MPWDirectoryReference*)aBinding
{
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWFileReference *binding in [aBinding contents]) {
        NSString *name=[(NSString*)[binding path] lastPathComponent];
        if ( ![name hasPrefix:@"."]) {
            if ( [binding hasChildren]) {
                name=[name stringByAppendingString:@"/"];
            }
            [names addObject:name];
        }
    }
    [self printNames:names limit:1000];
}

-(void)writeFancyDirectory:(MPWDirectoryReference*)aBinding
{
    for ( MPWFileReference *binding in [aBinding contents]) {
        [self writeFancyFileEntry:binding];
    }
}

-(void)writeInterpolatedString_disabled:(NSString*)s withEnvironment: theEnvironment
{
    [(MPWByteStream*)self.target writeInterpolatedString:s withEnvironment: theEnvironment];
}

-(void)print:s
{
    if ( [s isKindOfClass:[NSString class]]) {
        [self writeInterpolatedString:s withEnvironment: self.environment];
    } else {
        [super print:s];
    }
    
}

-(void)println:s
{
    if ( [s isKindOfClass:[NSString class]]) {
        [self writeInterpolatedString:s withEnvironment: self.environment];
        [self appendBytes:"\n" length:1];
    } else {
        [super println:s];
    }
    
}

@end

@implementation NSObject(shellPrinting)

-(void)writeOnShellPrinter:(MPWShellPrinter*)aPrinter
{
    [(id)self writeOnPropertyList:aPrinter];
}

@end
