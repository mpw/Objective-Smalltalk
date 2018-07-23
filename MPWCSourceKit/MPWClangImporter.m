//
//  MPWClangImporter.m
//  MPWCSourceKit
//
//  Created by Marcel Weiher on 7/23/18.
//

#import "MPWClangImporter.h"
#include "clang-c/Index.h"
#include "clang-c/CXCompilationDatabase.h"

@implementation MPWClangImporter
{
    CXIndex clangIndex;
    CXTranslationUnit translationUnit;
    CXFile file;
}

+(instancetype)importer
{
    return [[[self alloc] init] autorelease];
}

-(void)initializeTranslationUnit
{
    const char *argv[]={ "", "", NULL};
    int argc=0;
    const char *mainFile = "/tmp/hi.m";
    struct CXUnsavedFile unsaved[] = { {NULL, NULL, 0}};
    clangIndex = clang_createIndex(1, 1);

    
    
    
    translationUnit = clang_parseTranslationUnit(clangIndex, mainFile, argv, argc, unsaved,
                               0,
                               clang_defaultEditingTranslationUnitOptions());
}


-parseAFile
{
    [self initializeTranslationUnit];
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(translationUnit),
                                 ^ enum CXChildVisitResult (CXCursor cursor, CXCursor parent)
                                 {
                                     NSLog(@"found something");
                                     return CXChildVisit_Continue;
                                 });
    return nil;
}


@end

#import <MPWFoundation/DebugMacros.h>


@implementation MPWClangImporter(testing)


+(void)testGetInfoFromHeader
{
    MPWClangImporter *importer=[self importer];
    [importer parseAFile];
}

+testSelectors
{
    return @[
      @"testGetInfoFromHeader",
      ];
}

@end

