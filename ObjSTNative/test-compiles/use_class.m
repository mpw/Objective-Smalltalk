
#import <Foundation/Foundation.h>


id functionThatReferencesClass(void) {
    [NSNumber new];
    return [NSObject new];
}
