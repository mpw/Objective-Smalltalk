//
//  STHTMLGenerator.m
//  Sails
//
//  Created by Marcel Weiher on 21.04.26.
//

#import "STHTMLGenerator.h"



@implementation STHTMLGenerator

-(SEL)streamWriterMessage
{
    return @selector(generateHtml:);
}

-(void)writeTableRow:aRow ofTable:(MPWTable*)aTable
{
    NSArray <MPWTableColumn*>*columns=aTable.columns;
    [self tr:^{
        for (MPWTableColumn *column in columns ) {
            id value = [aRow at:column.key];
            [self td: value];
        }
    }];
}

-(void)writeTableHeader:(MPWTable*)aTable
{
    NSArray <MPWTableColumn*>*columns=aTable.columns;
    [self thead:^{
        for (MPWTableColumn *column in columns ) {
            [self th:column.title];
        }
    }];
}

-(void)writeTable:(MPWTable*)aTable
{
    [self table:^{
        [self writeTableHeader:aTable];
        [self tbody:^{
            [aTable rowsDo:^(id anObject){
                [self writeTableRow:anObject ofTable:aTable];
            }];
        }];
    }];
}


+(void)initialize
{
    static int initialized=NO;
    if (!initialized) {
        NSArray *tags=@[ @"body", @"table", @"tr", @"td" , @"th" ,@"thead", @"tbody"];
        [[self do] installElementNameWriter:[tags each]];
        initialized=YES;
    }
}

@end

@implementation NSObject(htmlGeneration)

-(void)generateHtml:(MPWXmlGeneratorStream*)aStream
{
    [self generateXmlContentOnto:aStream];
}

@end

@implementation MPWTable(htmlGeneration)

-(void)generateHtml:(MPWXmlGeneratorStream*)aStream
{
    [aStream writeTable:self];
}

-(BOOL)isSimpleXmlContent
{
    return NO;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STHTMLGenerator(testing) 

+(void)testGenerateSimpleHtml
{
    STHTMLGenerator *html=[self stream];
    [html html:@"Hello Html"];
    IDEXPECT( [[[html target] target] stringValue],@"<html>Hello Html</html>\n",@"simple html");
}

+(NSArray*)testSelectors
{
   return @[
			@"testGenerateSimpleHtml",
			];
}

@end
