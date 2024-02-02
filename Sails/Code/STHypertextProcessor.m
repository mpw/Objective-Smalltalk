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
@property (nonatomic,strong) MPWMAXParser *parser;
@property (nonatomic,strong) MPWByteStream *outstream;

@end


@implementation STHypertextProcessor

CONVENIENCEANDINIT( processor, WithCompiler:(STCompiler*)aCompiler )
{
    self=[super init];
    self.compiler = aCompiler;
    self.parser = [MPWMAXParser parser];
    self.outstream = [MPWByteStream stream];
    [self.parser setDelegate:self];
    
    return self;
}

-init
{
    return [self initWithCompiler:[STCompiler compiler]];
}

-process:dataOrString
{
    self.outstream.target = [NSMutableString string];
    [self.parser parse:dataOrString];
    return self.outstream.target;
}

-(void)parser:theParser foundProcessingInstructionWithTarget:tag data:d
{
    if ( [tag isEqual:@"st"] ) {
        [self.outstream print:[self.compiler evaluateScriptString:d]];
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
    id result=[[shp process:@"<?st 'Hello embedded ST: ', (3+4) stringValue.?>"] stringValue];
    IDEXPECT(result,@"Hello embedded ST: 7",@"3+4");
}

+(NSArray*)testSelectors
{
   return @[
			@"testHelloWorldFromWithinTemplate",
			];
}

@end
