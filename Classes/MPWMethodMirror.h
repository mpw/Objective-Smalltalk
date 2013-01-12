//
//  MPWMethodMirror.h
//  MPWTest
//
//  Created by Marcel Weiher on 5/30/11.
//  Copyright 2011 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPWMethodMirror : NSObject
{
	SEL selector;
	IMP imp;
	const char *typestring;
}

-initWithSelector:(SEL)newSel typestring:(const char*)newTypes;
-(SEL)selector;
-(IMP)imp;
-(void)setImp:(IMP)newImp;
@end
