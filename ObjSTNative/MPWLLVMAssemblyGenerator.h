//
//  MPWLLVMAssemblyGenerator.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 12/26/13.
//
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWLLVMAssemblyGenerator : MPWByteStream

-(void)writeHeaderWithName:(NSString*)name;
-(void)writeExternalReferenceWithName:(NSString*)name type:(NSString*)type;
-(void)writeClassWithName:(NSString*)aName superclassName:(NSString*)superclassName instanceMethodListRef:(NSString*)instanceMethodListSymbol;
-(void)writeTrailer;

-(NSString*)writeConstMethodAndMethodList:(NSString*)className methodName:(NSString*)methodName typeString:(NSString*)methodTypeString;

@end
