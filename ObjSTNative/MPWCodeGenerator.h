//
//  MPWCodeGenerator.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//

#import <Foundation/Foundation.h>

@class MPWLLVMAssemblyGenerator,MPWMethodDescriptor;


@interface MPWCodeGenerator : NSObject
{
    MPWLLVMAssemblyGenerator *assemblyGenerator;
}

+(instancetype)codegen;
-(void)flush;

@end
