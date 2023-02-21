//
//  MPWConnectToDefault.h
//  Arch-S
//
//  Created by Marcel Weiher on 8/8/12.
//
//

#import <ObjectiveSmalltalk/MPWExpression.h>

@interface MPWConnectToDefault : MPWExpression
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
