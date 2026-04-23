//
//  STHTMLGenerator.h
//  Sails
//
//  Created by Marcel Weiher on 21.04.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STHTMLGenerator : MPWXmlGenerator

-(void)tr:anObject;
-(void)th:anObject;
-(void)td:anObject;
-(void)table:anObject;

@end

NS_ASSUME_NONNULL_END
