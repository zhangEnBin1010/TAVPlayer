//
//  TPlayerMediaPlayback.h
//  timingapp
//
//  Created by enbin zhang on 2020/7/5.
//  Copyright © 2020 huiian. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "TAVPlayerPlayStatusDefines.h"
#import "TPlayerView.h"
@class TPlayerUrlSource, TPlayerErrorModel;
@protocol TPlayerManagerDelegate;

NS_ASSUME_NONNULL_BEGIN


@protocol TPlayerMediaPlayback <NSObject>

@required // 必须实现的方法 默认

/** 视频显示的view */
@property (nonatomic, strong, readwrite) TPlayerView *view;

@optional // 可选实现的方法

/** 音量 */
@property (nonatomic, assign) float volume;

/** 静音 */
@property (nonatomic, assign, getter=isMutea) BOOL muted;

/** 播放速度 */
@property (nonatomic, assign) float rate;

/** 当前播放的时间 */
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;

/** 总时长 */
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;

/** 缓冲时间 */
@property (nonatomic, assign, readonly) NSTimeInterval bufferTime;

/** seek time */
@property (nonatomic, assign, readonly) NSTimeInterval seekTime;

/** 播放状态:正在播放/没有播放 */
@property (nonatomic, assign, readonly) BOOL isPlaying;

/** 准备播放,如果为YES,你可以调用play,如果为NO,play自动调用prepareToPlay */
@property (nonatomic, assign, readonly) BOOL isPreparedToPlay;

/** 自动播放,default:YES */
@property (nonatomic, assign) BOOL shouldAutoPlay;

/** 视频大小 */
@property (nonatomic, assign, readonly) CGSize presentationSize;

/** 内容显示模式 */
@property (nonatomic, assign) TPlayerPlayerScalingMode scalingMode;

/** 播放状态 */
@property (nonatomic, assign, readonly) TPlayerEventType eventType;

/** 加载的状态 */
@property (nonatomic, assign, readonly) TPlayerLoadState loadState;

/** 是否循环播放 */
@property (nonatomic, assign) BOOL loop;

/// 播放器代理
@property(nonatomic, weak) id<TPlayerManagerDelegate> delegate;


/// URL播放
/// @param source URL资源
- (void)setUrlSource:(TPlayerUrlSource*)source;

/// 设置视频显示的view,必须要提供playerView的bounds
/// @param playerView  视频显示的view
- (void)setPlayerView:(UIView * _Nullable)playerView;

/// seek
/// @param time 时间
- (void)seekToTime:(NSTimeInterval)time;

/// seek
/// @param time 时间
/// @param completionHandler 完成的回调
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

/// 准备播放
- (void)prepareToPlay;

/// 播放
- (void)play;

/// 暂停
- (void)pause;

/// 恢复播放
- (void)resume;

/// 停止播放
- (void)stop;

@end

@protocol TPlayerManagerDelegate <NSObject>

@required // 必须实现的方法 默认

@optional // 可选实现的方法

/// 播放事件的回调
/// @param playerManager 管理类
/// @param eventType 事件状态
- (void)onPlayerManagerEvent:(id<TPlayerMediaPlayback>)playerManager eventType:(TPlayerEventType)eventType;

/// 加载事件的回调
/// @param playerManager 管理类
/// @param loadState 加载状态
- (void)onPlayerManagerLoad:(id<TPlayerMediaPlayback>)playerManager loadState:(TPlayerLoadState)loadState;

/// 播放进度的回调
/// @param playerManager 管理类
/// @param currentTime 当前时间
/// @param totalTime 总时长
/// @param progress 进度
- (void)onPlayerManagerPlayTimeChanged:(id<TPlayerMediaPlayback>)playerManager currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime progress:(float)progress;

/// 缓存进度的回调
/// @param playerManager 管理类
/// @param bufferTime 缓存时间
/// @param totalTime 总时长
/// @param progress 进度
- (void)onPlayerManagerBufferTimeChanged:(id<TPlayerMediaPlayback>)playerManager bufferTime:(NSTimeInterval)bufferTime totalTime:(NSTimeInterval)totalTime progress:(float)progress;

/// 播放器准备播放
/// @param playerManager 管理类
- (void)onPlayerManagerPlayerDidPrepareToPlay:(id<TPlayerMediaPlayback>)playerManager;

/// 播放器准备好播放
/// @param playerManager 管理类
- (void)onPlayerManagerPlayerDidReadyToPlay:(id<TPlayerMediaPlayback>)playerManager;

/// 播放完成
/// @param playerManager 管理类
- (void)onPlayerManagerDidToFinish:(id<TPlayerMediaPlayback>)playerManager;

/// 拖动完成
/// @param playerManager 管理类
- (void)onPlayerManagerPlayerDidSeekEnd:(id<TPlayerMediaPlayback>)playerManager;

/// 循环开始
/// @param playerManager 管理类
- (void)onPlayerManagerPlayerDidLoopingStart:(id<TPlayerMediaPlayback>)playerManager;

/// 视频尺寸改变
/// @param playerManager 管理类
/// @param presentationSize 视频大小
- (void)onPlayerManagerPresentationSizeChanged:(id<TPlayerMediaPlayback>)playerManager presentationSize:(CGSize)presentationSize;

/// 视频报错
/// @param playerManager 管理类
/// @param errorModel 错误
- (void)onError:(id<TPlayerMediaPlayback>)playerManager errorModel:(TPlayerErrorModel *_Nullable)errorModel;

@end


NS_ASSUME_NONNULL_END
