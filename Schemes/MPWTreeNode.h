//
//  MPWTreeNode.h
//  ObjectiveHTTPD
//
//  Created by Marcel Weiher on 7/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWTreeNode : MPWObject {
	id	name;
	id	parent;
	NSMutableArray*	_children;
	id  content;
}

+(instancetype)root;
-(BOOL)isRoot;
-(MPWTreeNode*)parent;
-nodeForPathEnumerator:(NSEnumerator*)enumerator;
-fileSystemPath;
-root;
-allSubnodes;
idAccessor_h( content, setContent )
-mkdirs:(NSEnumerator*)pathEnumerator;
-childWithName:childName;

@end
