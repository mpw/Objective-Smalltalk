//
//  SLInputField.m
//  Sails
//
//  Created by Marcel Weiher on 06.06.26.
//

#import "SLInputField.h"
#import "STHTMLGenerator.h"

@implementation SLInputField


-(instancetype)init
{
    self=[super init];
    self.type=@"text";
    return self;
}

-(void)generateHtml:(STHTMLGenerator*)htmlGen
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    attributes[@"type"]=self.type;
    attributes[@"class"]=self.name;
    attributes[@"name"]=self.name;
    if ( [self.type isEqual: @"checkbox"] ) {
        if (  [[self value] boolValue]) {
            attributes[@"checked"]=@"true";
        }
    } else {
        attributes[@"value"]=self.value;
    }
    attributes[@"hx-put"]=self.htmx_put;
    attributes[@"hx-post"]=self.htmx_post;

    [htmlGen input:@"" attributes:attributes];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation SLInputField(testing) 

+(void)testSimpleTextInputField
{
    STHTMLGenerator *html=[STHTMLGenerator stream];
    SLInputField *field=[[self new] autorelease];
    [html writeObject:field];
    IDEXPECT( [[html generated] stringValue] ,@"<input type='text'></input>\n",@"input text field");
}

+(NSArray*)testSelectors
{
   return @[
			@"testSimpleTextInputField",
			];
}

@end
