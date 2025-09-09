#import "ExampleHelper.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation ExampleHelper

+ (NSString *)getSystemVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)getDeviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

+ (NSNumber *)getBatteryLevel {
    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = YES;
    float level = device.batteryLevel;
    if (level < 0) {
        return @(-1); // unknown
    }
    return @(level * 100); // percentage
}

+ (NSDictionary *)getStorageInfo {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    NSNumber *freeSize = [attributes objectForKey:NSFileSystemFreeSize];
    NSNumber *totalSize = [attributes objectForKey:NSFileSystemSize];

    return @{
        @"free": freeSize ?: @(0),
        @"total": totalSize ?: @(0)
    };
}

@end
