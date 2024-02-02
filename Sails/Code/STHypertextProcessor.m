//
//  STHypertextProcessor.m
//  Sails
//
//  Created by Marcel Weiher on 02.02.24.
//

#import "STHypertextProcessor.h"
#import <ObjectiveSmalltalk/ObjectiveSmalltalk.h>

@interface STHypertextProcessor()

@property (nonatomic,strong) STCompiler *compiler;
@property (nonatomic,strong) MPWSAXParser *parser;
@property (nonatomic,strong) MPWByteStream *outstream;

@end


@implementation STHypertextProcessor

CONVENIENCEANDINIT( processor, WithCompiler:(STCompiler*)aCompiler )
{
    self=[super init];
    self.compiler = aCompiler;
    self.outstream = [MPWByteStream stream];
    self.parser = [MPWSAXParser parser];
    [self.compiler bindValue:self.outstream toVariableNamed:@"stdout"];
    [self.parser setDelegate:self];
    
    return self;
}

-init
{
    return [self initWithCompiler:[STCompiler compiler]];
}

-(void)process:dataOrString
{
    [self.parser parse:dataOrString];
}

-resultOfProcessing:dataOrString
{
    [self.outstream setByteTarget:[NSMutableString string]];
    [self process:dataOrString];
    return self.outstream.target;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
    [self.outstream printFormat:@"<%@>",elementName];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(nonnull NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName
{
    [self.outstream printFormat:@"</%@>",elementName];
}

-(void)parser:theParser foundCharacters:(nonnull NSString *)string
{
    NSLog(@"characters");
    [self.outstream writeObject:string];
}

-(void)parser:theParser foundProcessingInstructionWithTarget:tag data:d
{
    if ( [tag isEqual:@"st"] ) {
        id evalResult=[self.compiler evaluateScriptString:d];
        if ( [evalResult isNotNil]){
            [self.outstream print:evalResult];
        }
    } else {
        [self.outstream print:@"not an st script"];
    }
}

-(void)dealloc
{
    [_compiler release];
    [_parser setDelegate:nil];
    [_parser release];
    [_outstream release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STHypertextProcessor(testing) 

+(void)testHelloWorldFromWithinTemplate
{
    STHypertextProcessor *shp=[[self new] autorelease];
    id result=[shp resultOfProcessing:@"<?st stdout print:'Hello embedded ST: ', (3+4) stringValue.?>"];
    IDEXPECT(result,@"Hello embedded ST: 7",@"3+4");
}

+(void)testTemplateWithoutCodeGetsReproducedVerbating
{
    STHypertextProcessor *shp=[[self new] autorelease];
    NSString *template=@"<html><head><title>Great Title</title></head><body>Body Text</body></html>";
    id result=[shp resultOfProcessing:template];
    IDEXPECT(result,template,@"verbatim");
}

+(NSArray*)testSelectors
{
   return @[
       @"testHelloWorldFromWithinTemplate",
       @"testTemplateWithoutCodeGetsReproducedVerbating",
	];
}

@end
