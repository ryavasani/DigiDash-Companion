#import <Foundation/Foundation.h>

@interface ExampleHelper : NSObject

+ (NSString *)getSystemVersion;
+ (NSString *)getDeviceModel;
+ (NSNumber *)getBatteryLevel;
+ (NSDictionary *)getStorageInfo;

@end
