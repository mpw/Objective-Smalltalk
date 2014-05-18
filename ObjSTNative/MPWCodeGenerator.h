//
//  MPWCodeGenerator.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 2/26/13.
//
//

#import <Foundation/Foundation.h>

@class MPWLLVMAssemblyGenerator;

@interface MPWCodeGenerator : NSObject
{
    MPWLLVMAssemblyGenerator *assemblyGenerator;
}

+(instancetype)codegen;

@end
