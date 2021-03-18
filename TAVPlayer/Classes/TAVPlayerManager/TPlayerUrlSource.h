//
//  TPlayerUrlSource.h
//  timingapp
//
//  Created by enbin zhang on 2020/7/5.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPlayerUrlSource : NSObject

/** 播放器当前播放的item */
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;

/** 当前播放的资源 */
@property (nonatomic, strong, readonly) AVURLAsset *asset;

/** 视频请求头 */
@property (nonatomic, strong, readonly) NSDictionary *requestHeader;

/** 视频地址 */
@property (nonatomic, copy, readonly) NSString *url;

/// 网络地址初始化
/// @param url 地址
/// @param requestHeader 视频请求头
- (instancetype)initWithUrlWithString:(NSString*)url requestHeader:(nullable NSDictionary *)requestHeader;


/// 本地地址初始化
/// @param url 地址
- (instancetype)initWithFileURLWithPath:(NSString*)url;

@end

NS_ASSUME_NONNULL_END
