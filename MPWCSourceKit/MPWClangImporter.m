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

-(void)initializeTranslationUnit:(nullable NSString*)filename
{
    const char *argv[]={ "-v", "-v", NULL};
    int argc=2;
    const char *mainFile = "/tmp/hi.m";
    NSString *syntheticMainfile=[NSString stringWithFormat:@"#define nullable \n#define nonnull \n#import <Foundation/Foundation.h>\n"];
    struct CXUnsavedFile unsaved[] = {
        {mainFile, [syntheticMainfile UTF8String], [syntheticMainfile length]},
        {NULL, NULL, 0}};

    clangIndex = clang_createIndex(1, 1);

    
    
    
    translationUnit =
    clang_parseTranslationUnit(clangIndex, mainFile, argv, argc, unsaved,
                               1,
                               clang_defaultEditingTranslationUnitOptions());
}

-(NSString*)cxstringToNSString:(CXString)cxname
{
    const char *cstrname=clang_getCString(cxname);
    NSString *s=[NSString stringWithUTF8String:cstrname];
    return s;
}

-(NSString*)nameAtCursor:(CXCursor)aCursor
{
    return [self cxstringToNSString:clang_getCursorSpelling(aCursor)];
}

-(NSString*)typeAtCursor:(CXCursor)aCursor
{
    return [self cxstringToNSString:clang_getDeclObjCTypeEncoding(aCursor)];
}



-(void)handleInterface:(CXCursor)cursor
{
    printf("interface %s\n",[[self nameAtCursor:cursor] UTF8String]);

    clang_visitChildrenWithBlock(cursor,
                                 ^ enum CXChildVisitResult (CXCursor classCursor, CXCursor parent)
         {
             switch ( classCursor.kind) {
                 case CXCursor_ObjCInstanceMethodDecl:
                     printf(" instance method %s qualifiers: %x\n",[[self nameAtCursor:classCursor] UTF8String],clang_Cursor_getObjCDeclQualifiers(classCursor));
                     printf(" objc types %s\n",[[self typeAtCursor:classCursor] UTF8String]);
                     int numArgs=clang_Cursor_getNumArguments(classCursor);
                     printf(" %d arguments\n",numArgs);
                     for (int i=0;i<numArgs;i++) {
                         CXCursor argCursor=clang_Cursor_getArgument(classCursor,i);
                         CXType argType=clang_getCursorType(argCursor);
                         printf("  arg[%d] name=%s type=%s\n",i,
                                [[self nameAtCursor:argCursor] UTF8String],
                                [[self cxstringToNSString:clang_getTypeSpelling(argType)] UTF8String]
                                );
                         if (argType.kind==CXType_BlockPointer) {
                             printf("   block\n");
                             clang_visitChildrenWithBlock(argCursor,
                                                          ^ enum CXChildVisitResult (CXCursor blockCursor, CXCursor blockParent)
                                                          {
                                                              printf("   unhandled in block: %d\n",blockCursor.kind);
                                                              return CXChildVisit_Continue;

                                                          });
                         }
                     }

                     break;
                 case CXCursor_ObjCClassMethodDecl:
                     printf(" class method %s\n",[[self nameAtCursor:classCursor] UTF8String]);
                     break;
                 case CXCursor_ObjCPropertyDecl:
                     printf(" property decl %s\n",[[self nameAtCursor:classCursor] UTF8String]);
                     break;
                 default:
                     printf(" unhandled in interface: %d\n",classCursor.kind);
                     break;
                     
             }
             return CXChildVisit_Continue;
         });
}

-parseAFile
{
    [self initializeTranslationUnit:nil];
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(translationUnit),
                                 ^ enum CXChildVisitResult (CXCursor cursor, CXCursor parent)
         {
             switch ( cursor.kind) {
                 case CXCursor_ObjCInterfaceDecl:
                     [self handleInterface:cursor];
                     break;
                 case CXCursor_ObjCCategoryDecl:
                     printf("category\n");
                     break;
                 case CXCursor_FunctionDecl:
                     printf("function declaration\n");
                     break;
                 case CXCursor_EnumDecl:
                     printf("enum\n");
                     break;
                 case CXCursor_VarDecl:
                     printf("variable declaration\n");
                     break;
                 case CXCursor_TypedefDecl:
                     printf("typedef\n");
                     break;
                 default:
                     printf("unhandled: %d\n",cursor.kind);
             }
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

