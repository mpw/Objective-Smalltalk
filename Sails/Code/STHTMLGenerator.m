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

-(NSMutableDictionary*)inputAttributesForType:(MPWTypeDefinition*)type name:(NSString*)name value:value
{
    NSMutableDictionary *attributes=
    [[@{ @"class": name,
         @"name": name,
         /* @"disabled" : @"false" */ } mutableCopy] autorelease];
    
    char typeCode = type.objcTypeCode;
    switch ( typeCode ) {
        case 'B':
        {
            attributes[@"type"] = @"checkbox";
            if ( [value boolValue]) {
                attributes[@"checked"] = @"true";
            }
        }
            break;
        default:
            attributes[@"type"] = @"text";
            attributes[@"value"]=[value stringValue];
            break;
    }
    return attributes;
}


-(void)writeTableRow:(int)rowIndex ofTable:(MPWTable*)aTable
{
    NSArray <MPWTableColumn*>*columns=aTable.columns;
    [self tr:^{
        for (MPWTableColumn *column in columns ) {
            id value = [column objectAtIndex:rowIndex];
            NSMutableDictionary *attributes=[self inputAttributesForType:column.type name:column.key value:value];
            
            attributes[@"hx-put"]=[NSString stringWithFormat:@"/item/%d/%@",rowIndex,column.key];
             [self td: ^{
                [self input:@"" attributes:attributes];
            } attributes:@{ @"class": column.key}];

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

-(void)writeHTMXFormStruct:(MPWStructureDefinition*)theStruct postAction:(NSString*)actionString
{
    BOOL hasMoreThanOneField = [theStruct fields].count > 1;
    [self form:^{
        for ( MPWVariableDefinition *aField in theStruct.fields) {
            if ( hasMoreThanOneField ) {
                [self label:aField.title attributes:@{ @"for": aField.name} ];
            }
            NSDictionary *attributes=[self inputAttributesForType:aField.type name:aField.name value:@""];
            [self input:nil attributes:attributes];
        }
    }attributes:@{ @"hx-post": actionString  , @"id": theStruct.name , @"class": @"form-grid"}];
}

-(void)writeForm:(MPWForm*)aForm
{
    [self writeHTMXFormStruct: aForm.def  postAction: aForm.formAction];

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
            @"head",@"title",@"input",@"form",@"div",@"script",@"label",
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
