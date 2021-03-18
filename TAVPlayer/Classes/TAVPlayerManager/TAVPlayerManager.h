//
//  TAVPlayerManager.h
//  timingapp
//
//  Created by enbin zhang on 2020/7/3.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "TPlayerMediaPlayback.h"
#import "TPlayerUrlSource.h"
#import "TPlayerErrorModel.h"
@class TAVPlayerManager, TPlayerErrorModel, TAVUrlSource;


NS_ASSUME_NONNULL_BEGIN

@interface TAVPlayerManager : NSObject<TPlayerMediaPlayback>

/** AVPlayer(播放器) */
@property (nonatomic, strong, readonly) AVPlayer *player;
/** 当前播放的item */
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
/** 当前播放的asset */
@property (nonatomic, strong, readonly) AVURLAsset *asset;
/** 当前播放的URL */
@property (nonatomic, strong, readonly) NSURL *assetURL;

/** 是否有空闲的网络环境(网络环境资源充裕的情况下为YES,可通过KVO监听该值变化) */
@property (nonatomic, assign, readonly) BOOL isIdleNetworkEnvironment;

@property (nonatomic, assign) NSTimeInterval timeRefreshInterval;

+ (instancetype)manager;

+ (instancetype)new NS_UNAVAILABLE; 

- (instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
