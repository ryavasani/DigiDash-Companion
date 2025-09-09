#import "ExampleHelper.h"
#import <UIKit/UIKit.h>

@implementation ExampleHelper

+ (NSString *)getSystemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

@end
