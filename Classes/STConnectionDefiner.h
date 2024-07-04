//
//  STConnectionDefiner.h
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <ObjectiveSmalltalk/STExpression.h>

@interface STConnectionDefiner : STExpression
{
    id lhs,rhs;
}
-lhs;
-rhs;

@end


@interface NSObject(connecting)

-defaultComponentInstance;
+defaultComponentInstance;
-(Protocol*)defaultInputProtocol;
-defaultInputPort;
-defaultMessageInPortWithProtocol:aProtcol;
-defaultOutputPort;

-(NSDictionary*)ports;

@end
