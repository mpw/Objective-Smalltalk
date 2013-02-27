/*
 *  llvmincludes.h
 *  MPWCodeGen
 *
 *  Created by Marcel Weiher on 01/12/2005.
 *  Copyright 2005 __MyCompanyName__. All rights reserved.
 *
 */

#define __STDC_LIMIT_MACROS
#define __STDC_CONSTANT_MACROS


#include "llvm/ExecutionEngine/GenericValue.h"
#include "llvm/ExecutionEngine/Interpreter.h"
#include "llvm/ExecutionEngine/JIT.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

