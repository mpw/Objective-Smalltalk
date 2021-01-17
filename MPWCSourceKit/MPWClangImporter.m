//
//  MPWClangImporter.m
//  MPWCSourceKit
//
//  Created by Marcel Weiher on 7/23/18.
//

#import "MPWClangImporter.h"
#include "clang-c/Index.h"
#include "clang-c/CXCompilationDatabase.h"

@interface MPWClangImporter()

@property (nonatomic, strong) NSMutableDictionary *globals;
@property (nonatomic, strong) NSMutableDictionary *enumValues;


@end


@implementation MPWClangImporter
{
    CXIndex clangIndex;
    CXTranslationUnit translationUnit;
    CXFile file;
    
}

-(instancetype)init
{
    self=[super init];
    self.globals=[NSMutableDictionary dictionary];
    self.enumValues=[NSMutableDictionary dictionary];
    return self;
}

+(instancetype)importer
{
    return [[[self alloc] init] autorelease];
}

-(void)initializeTranslationUnit:(nullable NSString*)filename
{
    const char *argv[]={
//        "-F","/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks",
        "-F","/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks", "-framework","UIKit", NULL};
    int argc=2;
    const char *mainFile = "/tmp/hi.m";
//    NSString *syntheticMainfile=[NSString stringWithFormat:@"#define nullable \n#define nonnull \n#import <Foundation/Foundation.h>\n"];
    NSString *syntheticMainfile=[NSString stringWithFormat:@"#import <UIKit/UIKit.h>\n"];
    struct CXUnsavedFile unsaved[] = {
        {mainFile, [syntheticMainfile UTF8String], [syntheticMainfile length]},
        {NULL, NULL, 0}};

    clangIndex = clang_createIndex(1, 1);

    
    
    
    translationUnit =
    clang_parseTranslationUnit(clangIndex, mainFile, argv, argc, unsaved, 1,
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

-(long long)enumValueAtCursor:(CXCursor)aCursor
{
    return clang_getEnumConstantDeclValue(aCursor);
}

-(void)handleBlockArgumentsAndReturnTypes:(CXCursor)classCursor
{
    return ;
    printf("      block objc types %s\n",[[self typeAtCursor:classCursor] UTF8String]);
    clang_visitChildrenWithBlock(classCursor,
                                 ^ enum CXChildVisitResult (CXCursor blockArgCursor, CXCursor blockParent)
                                 {
                                     CXType argType=clang_getCursorType(blockArgCursor);
                                     printf("      arg of block name=%s type=%s\n",
                                            [[self nameAtCursor:blockArgCursor] UTF8String],
                                            [[self cxstringToNSString:clang_getTypeSpelling(argType)] UTF8String]);
                                     return CXChildVisit_Continue;
                                 });
}

-(void)handleBlockArg:(CXCursor)argCursor
{
    return ;
    CXType blockType=clang_getCursorType(argCursor);
   printf("   block name: %s type: %s\n",
           [[self nameAtCursor:argCursor] UTF8String],
          [[self cxstringToNSString:clang_getTypeSpelling(blockType)] UTF8String]);
    clang_visitChildrenWithBlock(argCursor,
                                 ^ enum CXChildVisitResult (CXCursor blockCursor, CXCursor blockParent)
         {
             switch (blockCursor.kind) {
                 case CXCursor_ParmDecl:
                 {
                     [self handleBlockArgumentsAndReturnTypes:blockCursor];
                 }
                 case CXCursor_UnexposedAttr:
                     break;
                 case CXCursor_ObjCClassRef:
                 {
                     CXType argType=clang_getCursorType(blockCursor);
                     printf("     block arg classref name=%s type=%s\n",
                            [[self nameAtCursor:blockCursor] UTF8String],
                            [[self cxstringToNSString:clang_getTypeSpelling(argType)] UTF8String]);
                     break;
                 }
                 default:
                     printf("     unhandled in block: %d\n",blockCursor.kind);

             }
             return CXChildVisit_Continue;
             
         });
    
}

-(void)handleArgumentsAndReturnTypes:(CXCursor)classCursor
{
//    printf(" %s qualifiers: %x\n",[[self nameAtCursor:classCursor] UTF8String],clang_Cursor_getObjCDeclQualifiers(classCursor));
//    printf(" objc types %s\n",[[self typeAtCursor:classCursor] UTF8String]);
    int numArgs=clang_Cursor_getNumArguments(classCursor);
//    printf(" %d arguments\n",numArgs);
    for (int i=0;i<numArgs;i++) {
        CXCursor argCursor=clang_Cursor_getArgument(classCursor,i);
        CXType argType=clang_getCursorType(argCursor);
//        printf("  arg[%d] name=%s type=%s\n",i,
//               [[self nameAtCursor:argCursor] UTF8String],
//               [[self cxstringToNSString:clang_getTypeSpelling(argType)] UTF8String]
//               );
        if (argType.kind==CXType_BlockPointer) {
            [self handleBlockArg:argCursor];
            
        }
    }

}

-(void)handleInterface:(CXCursor)cursor
{
//    printf("interface %s\n",[[self nameAtCursor:cursor] UTF8String]);
    
    clang_visitChildrenWithBlock(cursor,
                                 ^ enum CXChildVisitResult (CXCursor classCursor, CXCursor parent)
         {
             switch ( classCursor.kind) {
                 case CXCursor_ObjCInstanceMethodDecl:
                     [self handleArgumentsAndReturnTypes:classCursor];

                     break;
                 case CXCursor_ObjCClassMethodDecl:
//                     printf(" class method %s\n",[[self nameAtCursor:classCursor] UTF8String]);
                     break;
                 case CXCursor_ObjCPropertyDecl:
//                     printf(" property decl %s\n",[[self nameAtCursor:classCursor] UTF8String]);
                     break;
                 case CXCursor_TemplateTypeParameter:
//                     printf(" generic %s\n",[[self nameAtCursor:classCursor] UTF8String]);
                     break;
                 default:
//                     printf(" unhandled in interface: %d\n",classCursor.kind);
                     break;
                     
             }
             return CXChildVisit_Continue;
         });
}

-(void)handleEnumConstant:(CXCursor)cursor
{
//    printf("enum constant %s\n",[[self nameAtCursor:cursor] UTF8String]);

    clang_visitChildrenWithBlock(cursor,
                                 ^ enum CXChildVisitResult (CXCursor enumCursor, CXCursor parent)
         {
             switch ( enumCursor.kind) {
                 case CXCursor_EnumConstantDecl:
                     [self enumCase:[self nameAtCursor:enumCursor] value:(long)[self enumValueAtCursor:enumCursor]];
                     break;
                 case CXCursor_FirstAttr:
//                     printf("  first attr in enum constant %s\n",[[self nameAtCursor:enumCursor] UTF8String]);
                     break;
                 default:
//                     printf(" unhandled in enum constant: %d\n",enumCursor.kind);
                     break;
                     
             }
             return CXChildVisit_Continue;
         });
}

-(void)handleEnum:(CXCursor)cursor
{

    clang_visitChildrenWithBlock(cursor,
                                 ^ enum CXChildVisitResult (CXCursor classCursor, CXCursor parent)
         {
             switch ( classCursor.kind) {
                 case CXCursor_EnumConstantDecl:
                     [self handleEnumConstant:cursor];
//                     printf("  enum constant %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_FirstAttr:
//                     printf("  first attr in enum  %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 default:
//                     printf(" unhandled in enum: %d\n",classCursor.kind);
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
                 case CXCursor_TranslationUnit:
//                     printf("translation unit %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_ObjCProtocolDecl:
///                     printf("protocol declaration %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_StructDecl:
//                     printf("struct/union %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_ObjCInterfaceDecl:
                     [self handleInterface:cursor];
                     break;
                 case CXCursor_ObjCCategoryDecl:
//                     printf("category %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_ObjCProtocolRef:
//                     printf("@protocol %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 case CXCursor_ObjCClassRef:
//                     printf("@class %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;

                 case CXCursor_FunctionDecl:
//                     printf("function declaration\n");
                     break;
                 case CXCursor_EnumDecl:
                     [self handleEnum:cursor];
                     break;
                 case CXCursor_VarDecl:
                     [self globalVariable:[self nameAtCursor:cursor] type:[self typeAtCursor:cursor]];
                     break;
                 case CXCursor_TypedefDecl:
//                     printf("typedef: %s\n",[[self nameAtCursor:cursor] UTF8String]);
                     break;
                 default:
//                     printf("unhandled: %d\n",cursor.kind);
                     ;
             }
             return CXChildVisit_Continue;
         });
    
    [[NSJSONSerialization dataWithJSONObject:self.enumValues options:0 error:nil] writeToFile:@"/tmp/enums.json" atomically:YES];
    [[NSJSONSerialization dataWithJSONObject:self.globals options:0 error:nil] writeToFile:@"/tmp/globals.json" atomically:YES];

    return nil;
}


-(void)globalVariable:(NSString*)name type:(NSString*)type
{
//    printf("global variable: %s type %s\n",[name UTF8String],[type UTF8String]);
    self.globals[name]=type;
}

-(void)enumCase:(NSString*)name value:(long)value
{
    self.enumValues[name]=@(value);
//    printf("%s = %ld\n",[name UTF8String],value);
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

