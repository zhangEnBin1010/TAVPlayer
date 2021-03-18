//// TNetworkSpeedMonitor.h
// timingapp
//
// Copyright © 2020 huiian. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TDownloadNetworkSpeedNotificationKey;
extern NSString *const TUploadNetworkSpeedNotificationKey;
extern NSString *const TNetworkSpeedNotificationKey; // 网络速率(string)
extern NSString *const TNetworkSpeedValueNotificationKey; /// 网络速率(Int)


@interface TNetworkSpeedMonitor : NSObject

@property (nonatomic, copy, readonly) NSString *downloadNetworkSpeed;
@property (nonatomic, copy, readonly) NSString *uploadNetworkSpeed;

- (void)startNetworkSpeedMonitor;
- (void)stopNetworkSpeedMonitor;

@end

NS_ASSUME_NONNULL_END
