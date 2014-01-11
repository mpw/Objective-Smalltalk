//
//  MPWLLVMAssemblyGenerator.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/13.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWLLVMAssemblyGenerator : MPWByteStream
{
    NSMutableDictionary *selectorReferences;
    int numStrings;
    int numLocals;
    NSString *nsnumberclassref;
}

-(void)writeHeaderWithName:(NSString*)name;
-(void)writeExternalReferenceWithName:(NSString*)name type:(NSString*)type;
-(void)writeClassWithName:(NSString*)aName superclassName:(NSString*)superclassName instanceMethodListRef:(NSString*)instanceMethodListSymbol numInstanceMethods:(int)numInstanceMethods;
-(void)writeTrailer;
-(void)writeCategoryNamed:(NSString*)categoryName ofClass:(NSString*)aName instanceMethodListRef:(NSString*)instanceMethodListSymbol numInstanceMethods:(int)numInstanceMethods;


-(NSString*)methodListForClass:(NSString*)className methodNames:(NSArray*)methodNames methodSymbols:(NSArray*)methodSymbols methodTypes:(NSArray*)typeStrings;

-(NSString*)writeMethodNamed:(NSString*)methodName className:(NSString*)className methodType:(NSString*)methodType additionalParametrs:(NSArray*)params methodBody:(void (^)(MPWLLVMAssemblyGenerator*  ))block;
-(NSString*)stringRef:(NSString*)ref;
-(NSString*)writeNSNumberLiteralForInt:(NSString*)theIntSymbolOrLiteral;


-(void)flushSelectorReferences;

//--- temp/testing

-(NSString*)writeConstMethod1:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString;
-(NSString*)writeStringSplitter:(NSString*)className methodName:(NSString*)methodName methodType:(NSString*)typeString splitString:(NSString*)splitString;
-(NSString*)writeMakeNumberFromArg:(NSString*)className methodName:(NSString*)methodName;
-(NSString*)writeMakeNumber:(int)aNumber className:(NSString*)className methodName:(NSString*)methodName;
-(NSString*)writeUseBlockClassName:(NSString*)className methodName:(NSString*)methodName;
-(NSString*)writeCreateBlockClassName:(NSString*)className methodName:(NSString*)methodName userMessageName:(NSString*)userMessageName;


@end
