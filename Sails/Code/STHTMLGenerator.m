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


-(void)writeTableRow:(int)rowIndex ofTable:(MPWTable*)aTable
{
    NSArray <MPWTableColumn*>*columns=aTable.columns;
    [self tr:^{
        for (MPWTableColumn *column in columns ) {
            id value = [column objectAtIndex:rowIndex];
            char typeCode = column.type.objcTypeCode;
            switch ( typeCode ) {
                case 'B':
                {
                    NSMutableDictionary *attributes=
                    [[@{ @"class": column.key,
                         @"type": @"checkbox",
                         @"disabled" : @"true" } mutableCopy] autorelease];
                    if ( [value boolValue]) {
                        attributes[@"checked"] = @"true";
                    }
                    [self td: ^{
                        [self input:@"" attributes:attributes];
                    } attributes:@{ @"class": column.key}];
                }
                    break;
                default:
                    [self td: value attributes:@{ @"class": column.key}];
           }
        }
    }];
}

-(void)writeTableHeader:(MPWTable*)aTable
{
    NSArray <MPWTableColumn*>*columns=aTable.columns;
    [self thead:^{
        for (MPWTableColumn *column in columns ) {
            [self th:column.title attributes:@{ @"class": column.key}];
        }
    }];
}

-(void)writeTable:(MPWTable*)aTable
{
    [self table:^{
        [self writeTableHeader:aTable];
        [self tbody:^{
            [aTable rowsDo:^(NSNumber *rowIndex){
                [self writeTableRow:rowIndex.intValue ofTable:aTable];
            }];
        }];
    }  attributes:@{ @"class": aTable.tableIdentifier}];
}

-(void)closeEmptyElement
{
    FORWARDCHARS(">\n");
}



+(void)initialize
{
    static int initialized=NO;
    if (!initialized) {
        NSArray *elements=@[
            @"body", @"table", @"tr", @"td" , @"th" ,@"thead", @"tbody",
            @"head",@"title",@"input",@"form",@"div",@"script",
        ];
        [[self do] installElementNameWriter:[elements each]];
        NSArray *tags=@[
            @"p", @"br",
        ];
        [[self do] installEmptyElementNameWriter:[tags each]];
        initialized=YES;
    }
}

@end

@implementation NSObject(htmlGeneration)

-(void)generateHtml:(MPWXmlGenerator*)aStream
{
    [self generateXmlContentOnto:aStream];
}

@end

@implementation MPWTable(htmlGeneration)

-(void)generateHtml:(MPWXmlGenerator*)aStream
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
