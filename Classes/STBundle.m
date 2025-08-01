//
//  STBundle.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 05.08.20.
//

#import "STBundle.h"
#import "STCompiler.h"
#import "MPWSchemeScheme.h"
#import "MPWMethodStore.h"

@interface STBundle()

@property (nonatomic,strong) MPWReference *binding;
@property (readonly) NSString *path;

@end


@implementation STBundle
{
    NSDictionary      *info;
    STCompiler     *interpreter;
    NSDictionary      *methodDict;
    MPWWriteBackCache *cachedResources;
    MPWWriteBackCache *cachedSources;
}

lazyAccessor(NSDictionary*, info, setInfo, readInfo)
lazyAccessor(STCompiler*, interpreter, setInterpreter, createInterpreter)
lazyAccessor(NSDictionary*, methodDict, setMethodDict, methodDictForSourceFiles)
lazyAccessor(MPWWriteBackCache*, cachedResources, setCachedResources, createCachedResources)
lazyAccessor(MPWWriteBackCache*, cachedSources, setCachedSources, createCachedSources)
@dynamic info;

CONVENIENCEANDINIT( bundle, WithBinding:newBinding )
{
    self=[super init];
    self.binding=newBinding;
    self.saveSource = YES;
    return self;
}

CONVENIENCEANDINIT( bundle, WithPath:(NSString*)newPath )
{
    MPWDiskStore *ds=[MPWDiskStore store];
    MPWReference *binding=[ds bindingForReference:[MPWGenericIdentifier referenceWithPath:newPath] inContext:nil];
    return [self initWithBinding:binding];
}

-(NSString*)path
{
    return [self.binding path];
}

-(NSURL*)url
{
    return [NSURL fileURLWithPath:self.path];
}

-(MPWReference*)refForSubDir:(NSString*)subdir
{
    if ( subdir.length > 0) {
        return [[self binding] referenceByAppendingReference:subdir];
    } else {
        return [self binding];
    }
}

-(id <MPWHierarchicalStorage>)rawStoreForSubDir:(NSString*)subdir
{
    id scheme =  [[self refForSubDir:subdir] asScheme];
//    NSLog(@"raw scheme for subdir '%@' is %@",subdir,scheme);
    return scheme;
}

-(id <MPWHierarchicalStorage>)storeForSubDir:(NSString*)subdir
{
    id base = [self rawStoreForSubDir:subdir];
    return self.useCache ? [self cacheForBase:base] : base;

}

-(id <MPWHierarchicalStorage>)rawResources
{
    return [self rawStoreForSubDir:@"Resources"];
}

-(id <MPWHierarchicalStorage>)resources
{
    return self.useCache ? self.cachedResources : self.rawResources;
}

-(id <MPWHierarchicalStorage>)sources
{
    return self.useCache ? self.cachedSources : self.rawSources;
}


-(id <MPWHierarchicalStorage>)rawSources
{
    return [self rawStoreForSubDir:@"Sources"];
}

-(id <MPWHierarchicalStorage>)sourceDir
{
    return [self rawSources];          // compatibility
}


-(BOOL)isPresentOnDisk
{
    MPWReference *binding=[self binding];
    @try {
        BOOL exists = [binding isBound];
        return exists;
    } @catch ( NSException *exception ) {
        return NO;
    }
}

-(id <MPWIdentifying>)sourceRef
{
    return [self refForSubDir:@"Sources"];
//    NSString *path=[[self path] stringByAppendingPathComponent:@"Resources"];
//    return path;
}

-(id <MPWIdentifying>)resourceRef
{
    NSString *path=[[self path] stringByAppendingPathComponent:@"Resources"];
    return path;
}

-(MPWWriteBackCache*)cacheForBase:(id <MPWStorage,MPWHierarchicalStorage>) base
{
    MPWWriteBackCache *cache=[MPWWriteBackCache storeWithSource:base];
    cache.autoFlush=NO;
//    NSLog(@"cache for base %@ is %@",base,cache);
    return cache;
}

-(MPWWriteBackCache*)createCachedResources
{
    return [self cacheForBase:self.rawResources];
}

-(MPWWriteBackCache*)createCachedSources
{
    return [self cacheForBase:self.rawSources];
}


-(NSArray<NSString*>*)sourceNames
{
    
    NSArray<NSString*>* allFiles = (NSArray<NSString*>*)[[(NSArray<NSString*>*)[[[[[self sourceDir] at:@""] contents] collect] path] collect] lastPathComponent];
    return [[allFiles select] __hasSuffix:@"st"];
}

-(NSDictionary*)readInfo
{
    NSString *path = [self.path stringByAppendingPathComponent:@"Info.json"];
    NSData *infoData = [NSData dataWithContentsOfFile:path];
    // FIXME:  the following does not work on Android/GNUstep
    // NSLog(@"data via stores: %@",[[self rawStoreForSubDir:@""][@"Info.json"] stringValue]);
    return infoData ?  [NSJSONSerialization JSONObjectWithData:infoData options:0 error:nil] : nil;
}

-(void)configureInterpreter:(STCompiler*)newInterpreter
{
    [[newInterpreter schemes] setSchemeHandler:self.cachedResources   forSchemeName:@"rsrc"];
//    NSLog(@"configuring interpreter %@ with rsrc scheme: %@",newInterpreter,[newInterpreter evaluateScriptString:@"scheme:rsrc"]);
    id ststdout = [MPWByteStream Stdout];
    [newInterpreter bindValue:ststdout toVariableNamed:@"stdout"];
    [newInterpreter bindValue:[MPWPrintLiner streamWithTarget:ststdout] toVariableNamed:@"stdline"];
}

-(STCompiler*)createInterpreter
{
    STCompiler *compiler = [STCompiler compiler];
    [self configureInterpreter:compiler];
    return compiler;
}

-(id)resultOfCompilingSourceFileNamed:(NSString*)sourceName
{
    id statements=nil;
    @autoreleasepool {
        STCompiler *compiler=self.interpreter;
        id <MPWHierarchicalStorage> sources=[self cachedSources];
        NSData *stSource = sources[sourceName];
        statements=[[compiler compile:stSource] retain];
    }
    return [statements autorelease];
}

-(void)compileSourceFile:(NSString*)sourceName
{
    @autoreleasepool {
        [self.interpreter evaluate:[self resultOfCompilingSourceFileNamed:sourceName]];
    }
}

-(void)compileAllSourceFiles
{
    NSLog(@"=== compile all source files ===");
    for ( NSString *filename in [self sourceNames] ) {
        @autoreleasepool {
            NSLog(@"compile %@",filename);
            [self compileSourceFile:filename];
        }
    }
    NSLog(@"=== done compiling ===");
}

-(NSDictionary*)methodDictForSourceFiles
{
    [self compileAllSourceFiles];
    return [self.interpreter externalScriptDict];
}

-(void)copySource:(id <MPWStorage>)source to:(id <MPWStorage>)target
{
    NSArray *children=[source childrenOfReference:@""];
    for ( id child in children ) {
        target[child] = source[child];
    }
}

-(void)writeToStore:(id <MPWStorage>)target
{
    [self methodDict];
    [target mkdirAt:@""];
    [target mkdirAt:@"Sources"];
    [target mkdirAt:@"Resources"];
    target[@"Info.json"] = [self rawStoreForSubDir:@""][@"Info.json"];
    
    [self copySource:[self resources] to:[target relativeStoreAt:@"Resources"]];
    [self copySource:[self sources] to:[target relativeStoreAt:@"Sources"]];

    //   fileout code, inactive and doesn't work with property paths
    //    if ( self.saveSource ) {
    //        [[self.interpreter methodStore] fileoutToStore:[target relativeStoreAt:@"Sources"]];
    //    } else {
    //
    //    }

    
}

-(NSURL*)urlAt:(NSString*)name
{
    return [NSURL URLWithString:name relativeToURL:self.url];
}

-(BOOL)writeData:(NSData*)data at:(NSString*)name
{
    return [data writeToURL:[self urlAt:name] atomically:YES];
}

-(BOOL)createDirectoryAt:(NSString*)name
{
    NSError *outError=nil;
    NSURL *dir=[NSURL URLWithString:name relativeToURL:self.url];
    return [[NSFileManager defaultManager] createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:&outError];
}

-(void)save
{
    [self createDirectoryAt:@""];
    NSDictionary *localInfo=self.info ?: @{};
    [self writeData:[NSJSONSerialization dataWithJSONObject:localInfo options:0 error:nil] at:@"Info.json"];
    if ( self.saveSource) {
        [self createDirectoryAt:@"Sources"];
        [[self.interpreter methodStore] fileoutToStore:self.sourceDir];
        [self.cachedSources flush];
    }
    [self createDirectoryAt:@"Resources"];
    [self.cachedResources flush];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation STBundle(testing)

+(instancetype)_testBundle
{
    NSString *testBundlePath=[[NSBundle bundleForClass:self] pathForResource:@"test" ofType:@"stb"];
    STBundle *bundle=[self bundleWithPath:testBundlePath];
    EXPECTNOTNIL(testBundlePath, @"bundle url");
    return bundle;
}

+(void)testBasicCreation
{
    STBundle *bundle=[self _testBundle];
    IDEXPECT([[bundle path] lastPathComponent],@"test.stb",@"bundle URL ivar");
}

+(void)testGetResource
{
    STBundle *bundle=[self _testBundle];
    NSData *png=[bundle resources][@"objst.png"];
    EXPECTNOTNIL(png, @"got the png");
    INTEXPECT(png.length, 4908, @"and it is the png I expected");
}

+(void)testGetSource
{
    STBundle *bundle=[self _testBundle];
    NSData *source=[bundle sourceDir][@"STBundleLoadedTestClass2.st"];
    EXPECTNOTNIL(source, @"got the source");
    INTEXPECT(source.length, 91, @"and it is the source I expected");
}

+(void)testGetAllSourceNames
{
    STBundle *bundle=[self _testBundle];
    NSArray<NSString*> *names=[bundle sourceNames];
    INTEXPECT(names.count, 2, @"number of source files");
    NSData *s1=[bundle sourceDir][names[0]];
    IDEXPECT(names[0], @"STBundleLoadedTestClass1.st", @"what is it?");
    INTEXPECT(s1.length,92,@"source file 1");
}

+(void)testReadInfo
{
    STBundle *bundle=[self _testBundle];
    NSDictionary *info=[bundle readInfo];
    IDEXPECT(info[@"site"], @"ObjectiveSTSite",@"site class name");
}

+(void)testGetInfo
{
    STBundle *bundle=[self _testBundle];
    NSDictionary *info=[bundle info];
    IDEXPECT(info[@"site"], @"ObjectiveSTSite",@"site class name");
}

+(void)testGetInterpreter
{
    STBundle *bundle=[self _testBundle];
    STCompiler *interpreter=[bundle interpreter];
    IDEXPECT( [interpreter evaluateScriptString:@"3+4"], @(7), @"interpreter works");
    NSData *png=[interpreter evaluateScriptString:@"rsrc:objst.png"];
    EXPECTNOTNIL(png, @"got the png");
    INTEXPECT(png.length, 4908, @"and it is the png I expected");

}

+(void)testCompileSources
{
    STBundle *bundle=[self _testBundle];
    NSDictionary *methodDict=[bundle methodDict];
    INTEXPECT( methodDict.count, 2, @"number of classes in methodDict");
}

+(void)testExistsOnDisk
{
    STBundle *bundleThatExists=[self _testBundle];
    EXPECTTRUE(bundleThatExists.isPresentOnDisk, @"isPresentOnDisk for one that exists");
    STBundle *bundleThatDoesNotExist=[self bundleWithPath:@"/bizzarePath/thisshouldntexist.stb"];
    EXPECTFALSE(bundleThatDoesNotExist.isPresentOnDisk, @"isPresentOnDisk for one that does not exist");
}

+(void)testWriteInfo
{
    NSString *newBundlePath=@"/tmp/testinfobundle.stb";
    NSError *error=nil;
    [[NSFileManager defaultManager] removeItemAtPath:newBundlePath error:&error];
//    NSLog(@"error before: %@",error);
    STBundle *newBundle=[self bundleWithPath:newBundlePath];
    EXPECTNIL( newBundle.info, @"info");
    newBundle.info = @{ @"siteClass": @"MyTestSite "};
    EXPECTNOTNIL( newBundle.info, @"info");
    [newBundle save];
    
    STBundle *checkBundle = [STBundle bundleWithPath:newBundlePath];
    EXPECTNOTNIL(checkBundle.info, @"info when checking");
    
//    NSLog(@"error after: %@",error);
}

+(void)testWriteResources
{
    NSString *newBundlePath=@"/tmp/testresourcesbundle.stb";
    NSError *error=nil;
    [[NSFileManager defaultManager] removeItemAtPath:newBundlePath error:&error];
//    NSLog(@"error before: %@",error);
    STBundle *newBundle=[self bundleWithPath:newBundlePath];
    EXPECTNIL(newBundle.cachedResources[@"index.html"],@"index.html should be nil before" );
    newBundle.cachedResources[@"index.html"]=@"Hello World!";
    EXPECTNOTNIL(newBundle.cachedResources, @"should have a resources ")
    [newBundle save];
    
    STBundle *checkBundle = [STBundle bundleWithPath:newBundlePath];
    EXPECTNOTNIL(checkBundle.cachedResources[@"index.html"],@"index.html should now exist" );
//    NSLog(@"error after: %@",error);
}

+(NSArray*)testSelectors
{
    return @[
        @"testBasicCreation",
        @"testGetResource",
        @"testGetSource",
        @"testGetAllSourceNames",
        @"testReadInfo",
        @"testGetInfo",
        @"testGetInterpreter",
        @"testCompileSources",
        @"testExistsOnDisk",
        @"testWriteInfo",
        @"testWriteResources",
    ];
}
@end
