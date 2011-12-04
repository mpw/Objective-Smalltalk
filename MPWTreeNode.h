//
//  MPWTreeNode.h
//  MPWSideweb
//
//  Created by Marcel Weiher on 7/9/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <MPWFoundation/MPWFoundation.h>


@interface MPWTreeNode : MPWObject {
	id	name;
	id	parent;
	id	_children;
	id  content;
}

-(BOOL)isRoot;
-(MPWTreeNode*)parent;
-fileSystemPath;
-root;
-allSubnodes;

@end
