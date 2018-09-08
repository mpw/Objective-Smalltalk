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
    int width = w.ws_col;
    if ( width == 0 ) {
        width=80;
    }
    return width;
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

-(void)writeFancyFileEntry:(MPWFileBinding*)binding
{
    NSFileManager *fm=[NSFileManager defaultManager];
    NSString *path=(NSString*)[binding path];
    NSString *name=[binding fancyPath];
    if ( ![name hasPrefix:@"."]) {
        NSDictionary *attributes=[fm attributesOfItemAtPath:path error:nil];
        NSNumber *size=[attributes objectForKey:NSFileSize];
        NSString *formattedSize=[NSByteCountFormatter stringFromByteCount:[size intValue] countStyle:NSByteCountFormatterCountStyleBinary /* NSByteCountFormatterCountStyleFile */];
        formattedSize=[formattedSize stringByReplacingOccurrencesOfString:@" bytes" withString:@"  B"];
        int numSpaces=10-(int)[formattedSize length];
        numSpaces=MAX(0,numSpaces);
        NSString *spaces=[@"               " substringToIndex:numSpaces];
        [self printFormat:@"%@%@  %@%c\n",spaces,formattedSize,name,[binding hasChildren] ? '/':' '];
    }
}

-(void)writeDirectory:(MPWDirectoryBinding*)aBinding
{
    NSMutableArray *names=[NSMutableArray array];
    for ( MPWFileBinding *binding in [aBinding contents]) {
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

-(void)writeFancyDirectory:(MPWDirectoryBinding*)aBinding
{
    for ( MPWFileBinding *binding in [aBinding contents]) {
        [self writeFancyFileEntry:binding];
    }
}

-(void)writeInterpolatedString:(NSString*)s withEnvironment: theEnvironment
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
        [(MPWByteStream*)self.target outputString:@"\n"];
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
