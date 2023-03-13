//
//  MPWConnectToDefault.h
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <ObjectiveSmalltalk/STExpression.h>

@interface MPWConnectToDefault : STExpression
{
    id lhs,rhs;
}
-lhs;
-rhs;

@end


@interface NSObject(connecting)

-defaultComponentInstance;
+defaultComponentInstance;
-defaultInputPort;
-defaultOutputPort;

-(NSDictionary*)ports;

@end
