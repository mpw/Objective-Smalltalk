//
//  MPWTreeNode.m
//  ObjectiveHTTPD
//
//  Created by Marcel Weiher on 7/9/07.
//  Copyright 2007 Marcel Weiher. All rights reserved.
//

#import "MPWTreeNode.h"

@interface NSObject(contentProtocolForExternalPaths)

-(NSString*)fileSystemPathForBasePath:(NSString*)basePath;

@end

@implementation MPWTreeNode

idAccessor( name, setName )
scalarAccessor( id, parent, setParent )
idAccessor( _children, setChildren )
idAccessor( content, setContent )

+nodeWithName:newName
{
	return [[[self alloc] initWithName:newName] autorelease];
}

-initWithName:newName
{
	self=[super init];
	[self setName:newName];
	return self;
}

-init
{
	return [self initWithName:@""];
}

+(instancetype)root
{
	return [self nodeWithName:@""];
}

-root
{
	return parent ? [parent root] : self;
}	

-children
{
	id children=[self _children];
	if ( !children ) {
		[self setChildren:children=[NSMutableArray array]];
	}
	return children;
}

-(BOOL)hasChildren
{
    return [[self children] count] > 0;
}

-addChild:newChild
{
	[newChild setParent:self];
	[[self children] addObject:newChild];
	return newChild;
}

-mkdir:newName
{
	return [self addChild:[[self class] nodeWithName:newName]];
}

-childWithName:childName
{
	int i,max;
	id children=[self _children];
	for (i=0,max=(int)[children count]; i<max; i++) {
		id thisChild = [children objectAtIndex:i];
		if ( [[thisChild name] isEqual:childName] ) {
			return thisChild;
		}
	}
	return nil;
}


-mkdirs:(NSEnumerator*)pathEnumerator
{
    NSString *nextName=[pathEnumerator nextObject];
    if ( nextName ) {
        MPWTreeNode *nextNode=[self childWithName:nextName];
        if ( !nextNode ) {
            nextNode=[self mkdir:nextName];
        }
        return [nextNode mkdirs:pathEnumerator];
    }
    return self;
}

-nodeForPathComponent:(NSString*)pathComponent
{
	if ( [pathComponent length] == 0 || [pathComponent isEqual:@"."] ) {
		return self;
	} else {
		return [self childWithName:pathComponent];
	}
}

-nodeForPathEnumerator:(NSEnumerator*)enumerator
{
	id nextName=[enumerator nextObject];
	if ( nextName ) {
		return [[self nodeForPathComponent:nextName] nodeForPathEnumerator:enumerator];
	} else {
		return self;
	}
}

-nodeForPath:(NSString*)pathString
{
	id pathArray=[pathString componentsSeparatedByString:@"/"];
	return [self nodeForPathEnumerator:[pathArray objectEnumerator]];
}

-(void)renderOn:aRenderer
{
	[aRenderer writeObject:[self content]];
}

-path
{
	if ( [self parent] ) {
		return [[[self parent] path] stringByAppendingPathComponent:[self name]];
	} else {
		return @"/";
	}
}

-asReference
{
    return [MPWGenericReference referenceWithPath:[self path]];
}

-fileSystemPath
{
	return [[self content] fileSystemPathForBasePath:[self path]];  // external ...
}


-(BOOL)isRoot
{
	return [self parent] == nil;
}

-accumulateSelfAndAllSubnodesInto:anArray
{
	int i;
	[anArray addObject:self];
	if (_children) {
		for (i=0;i<[_children count]; i++) {
			[[_children objectAtIndex:i] accumulateSelfAndAllSubnodesInto:anArray];
		}
	}
	return anArray;
}

-relativePathComponents
{
    return @[];
}

-allSubnodes
{
	return [self accumulateSelfAndAllSubnodesInto:[NSMutableArray array]];
}

-(void)dealloc
{
	[name release];
	[_children release];
	[content release];
	[super dealloc];
}

-description
{
	return [NSString stringWithFormat:@"<%@:%p name: %@>",[self class],self,[self name]];
}

@end


@implementation MPWTreeNode(testing)

+(void)testNameSetting
{
	MPWTreeNode* node=[[self new] autorelease];
	NSString* testName=@"my name";
	[node setName:testName];
	IDEXPECT( [node name], testName, @"the name we set");
}

+(void)testAddAndRetrieveChild
{
	NSString* childName=@"childName";
	MPWTreeNode* root=[self root];
	MPWTreeNode* child=[self nodeWithName:childName];
	[root addChild:child];
	IDEXPECT( [child parent], root , @"child's root");
	IDEXPECT( [root childWithName:@"childName"], child , @"child at name");
}


+(void)testPathReporting
{
	id expectedPath=@"/firstLevel/secondLevel";
	id root = [self root];
	id secondLevel;
	secondLevel = [[root mkdir:@"firstLevel"] mkdir:@"secondLevel"];
	IDEXPECT( [secondLevel path], expectedPath, @"path of second level node" );
}
+(void)testPathRetrieving
{
	id expectedPath=@"/firstLevel/secondLevel";
	id root = [self root];
	id secondLevel;
	secondLevel = [[root mkdir:@"firstLevel"] mkdir:@"secondLevel"];
	IDEXPECT( [root nodeForPath:expectedPath], secondLevel ,@"retrieve node by path" );
	IDEXPECT( [root nodeForPath:@"/"], root ,@"retrieve root by path" );
}

+(void)testKnowsRoot
{
	MPWTreeNode* root = [self root];
	MPWTreeNode* secondLevel;
	MPWTreeNode* firstLevel = [root mkdir:@"firstLevel"];
	secondLevel = [firstLevel mkdir:@"secondLevel"];


	NSAssert( [root isRoot], @"root knows it's root" );


	NSAssert( ![secondLevel isRoot], @"secondLevels knows it's not root" );
	NSLog(@"firstlevel %p secondLevel parent: %p",firstLevel, [secondLevel parent]);
	NSLog(@"[[secondLevel parent] isRoot]=%x",[[secondLevel parent] isRoot]);
	NSLog(@"[firstLevel isRoot]=%x",[firstLevel isRoot]);
	NSAssert( ![[secondLevel parent] isRoot], @"first level knows it's not root" );

}

+(void)testAllSubnodes
{
	id root = [self root];
	id allSubnodes;
	id child1,child2;
	allSubnodes=[root allSubnodes];
	INTEXPECT( [allSubnodes count] ,1 ,@"allSubnodes with only root");
	child1 = [root mkdir:@"firstChild"];
	allSubnodes=[root allSubnodes];
	INTEXPECT( [allSubnodes count] ,2 ,@"allSubnodes with root and child");
	NSAssert( [allSubnodes containsObject:root], @"should contain root");
	NSAssert( [allSubnodes containsObject:child1], @"should contain child1");
	child2=[root mkdir:@"child2"];
	allSubnodes=[root allSubnodes];
	INTEXPECT( [allSubnodes count] ,3 ,@"allSubnodes with root and 2 children");
    IDEXPECT( [child2 path], @"/child2", @"child2 path");
}

+(void)testMkdirs
{
	id root = [self root];
    NSString *path=@"hi/there";
    NSArray *pathArray=[path componentsSeparatedByString:@"/"];
    EXPECTNIL([root nodeForPath:path] , @"shouldn't have path before mkdir" );
    [root mkdirs:[pathArray objectEnumerator]];
    EXPECTNOTNIL([root nodeForPath:path] , @"should  have path after mkdir" );
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testNameSetting",
			@"testAddAndRetrieveChild",
			@"testPathReporting",
			@"testPathRetrieving",
			@"testKnowsRoot",
			@"testAllSubnodes",
            @"testMkdirs",
			nil];
}


@end

