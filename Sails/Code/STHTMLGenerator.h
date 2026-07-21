//
//  STHTMLGenerator.h
//  Sails
//
//  Created by Marcel Weiher on 21.04.26.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STHTMLGenerator : MPWXmlGenerator

@property (nonatomic,strong) NSString *basePath;

@end

@interface STHTMLGenerator(generated)

-(void)tr:anObject;
-(void)tr:anObject attributes:attrs;
-(void)th:anObject attributes:attrs;
-(void)td:anObject attributes:attrs;
-(void)table:anObject attributes:attrs;
-(void)thead:anObject;
-(void)tbody:anObject;
-(void)input:anObject attributes:attrs;
-(void)label:anObject attributes:attrs;
-(void)form:anObject attributes:attrs;
-(void)textarea:anObject attributes:attrs;

@end


NS_ASSUME_NONNULL_END
