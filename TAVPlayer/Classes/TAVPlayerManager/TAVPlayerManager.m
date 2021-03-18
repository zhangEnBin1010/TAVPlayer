//
//  TAVPlayerManager.m
//  timingapp
//
//  Created by enbin zhang on 2020/7/3.
//  Copyright © 2020 huiian. All rights reserved.
//

/**
 * @功能描述：AVPlayer管理类
 * @创建人：章恩斌
 * @创建日期：2020-07-03
 */

#import "TAVPlayerManager.h"
#import "TAVKVOController.h"
#import "TPlayerView.h"
#import "TNetworkSpeedMonitor.h"
#import "ZEBReachability.h"

/*!
 *  监听AVPlayer
 */
static NSString *const kStatus                    = @"status"; //播放器项目的状态
static NSString *const kLoadedTimeRanges          = @"loadedTimeRanges"; //时间范围数组，指示易于获得的媒体数据。
static NSString *const kPlaybackBufferEmpty       = @"playbackBufferEmpty"; //播放是否已耗尽所有缓冲的媒体，并且播放将停止还是结束。
static NSString *const kPlaybackLikelyToKeepUp    = @"playbackLikelyToKeepUp"; //该项目是否可能在不停顿的情况下播放
static NSString *const kPlaybackBufferFull        = @"playbackBufferFull"; // 缓存区是否已经满了，并且进一步的I / O是否被挂起
static NSString *const kPresentationSize          = @"presentationSize"; //视频尺寸
static NSString *const kReadyForDisplay           = @"readyForDisplay"; //第一帧显示
static NSString *const kTimeControlStatus         = @"timeControlStatus"; //一种状态，指示在等待适当的网络条件时是当前正在进行播放，无限期暂停还是暂停播放

@interface TAVPlayerPresentView : TPlayerView

@property (nonatomic, strong) AVPlayer *player;
/// default is AVLayerVideoGravityResizeAspect.
@property (nonatomic, strong) AVLayerVideoGravity videoGravity;

@end

@implementation TAVPlayerPresentView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)avLayer {
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)setPlayer:(AVPlayer *)player {
    if (player == _player) return;
    self.avLayer.player = player;
}

- (void)setVideoGravity:(AVLayerVideoGravity)videoGravity {
    if (videoGravity == self.videoGravity) return;
    [self avLayer].videoGravity = videoGravity;
}

- (AVLayerVideoGravity)videoGravity {
    return [self avLayer].videoGravity;
}

@end

@interface TAVPlayerManager () {
    id _timeObserver;
    id _itemEndObserver;
    TAVKVOController *_playerItemKVO;
    TAVKVOController *_playerLayerKVO;
    TAVKVOController *_playerKVO;
    int _downSpeed;
}

/** 视频播放URL资源 */
@property (nonatomic, strong) TPlayerUrlSource *urlSource;
@property (nonatomic, assign) BOOL isBuffering;
@property (nonatomic, assign) BOOL isReadyToPlay;
/** 播放状态 */
@property (nonatomic, assign) TPlayerEventType eventType;
/** 加载状态 */
@property (nonatomic, assign) TPlayerLoadState loadState;
/** 是否正在seek */
@property (nonatomic, assign) BOOL isSeek;
/** 网速监听类 */
@property (nonatomic, strong) TNetworkSpeedMonitor *speedMonitor;
@end

@implementation TAVPlayerManager

@synthesize view                           = _view;
@synthesize volume                         = _volume;
@synthesize muted                          = _muted;
@synthesize rate                           = _rate;
@synthesize currentTime                    = _currentTime;
@synthesize totalTime                      = _totalTime;
@synthesize bufferTime                     = _bufferTime;
@synthesize seekTime                       = _seekTime;
@synthesize isPlaying                      = _isPlaying;
@synthesize isPreparedToPlay               = _isPreparedToPlay;
@synthesize shouldAutoPlay                 = _shouldAutoPlay;
@synthesize scalingMode                    = _scalingMode;
@synthesize presentationSize               = _presentationSize;
@synthesize delegate                       = _delegate;
@synthesize loop                           = _loop;

static TAVPlayerManager *_sharedInstance = nil;
+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //不能再使用alloc方法
        //因为已经重写了allocWithZone方法，所以这里要调用父类的分配空间的方法
        _sharedInstance = [[self alloc]init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //设置默认内容展示样式
        self.scalingMode = TPlayerPlayerScalingModeAspectFit;
        _shouldAutoPlay = YES;
        self.speedMonitor = [[TNetworkSpeedMonitor alloc] init];
        [self.speedMonitor startNetworkSpeedMonitor];
        _isIdleNetworkEnvironment = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkSpeedChanged:) name:TDownloadNetworkSpeedNotificationKey object:nil];
    }
    return self;
}

- (void)prepareToPlay {
    _isPreparedToPlay = YES;
    [self switchSource];
    if (self.shouldAutoPlay) {
        [self play];
    }
    self.loadState = TPlayerLoadStatePrepareing;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayerDidPrepareToPlay:)]) {
        [self.delegate onPlayerManagerPlayerDidPrepareToPlay:self];
    }
}

- (void)play {
    if (!_isPreparedToPlay) {
        [self prepareToPlay];
    } else {
        [self changeIsIdleNetworkEnvironment:NO];
        [self.player play];
        self.player.rate = self.rate;
        self->_isPlaying = YES;
        [self toEvaluatingStartLoading];
    }
}

- (void)pause {
    self->_isPlaying = NO;
    self.eventType = TPlayerEventLoadingEnd;
    [_playerItem cancelPendingSeeks];
    [_asset cancelLoading];
    [self.player pause];
}

- (void)resume {
    if (!self.isPlaying) [self play];
}

- (void)stop {
    [_playerItemKVO safelyRemoveAllObservers];
    self.loadState = TPlayerLoadStateUnknown;
    [self pause];
    [self.player removeTimeObserver:_timeObserver];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    _timeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:_itemEndObserver name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    _itemEndObserver = nil;
    self->_isPlaying = NO;
    _assetURL = nil;
    _playerItem = nil;
    _player = nil;
    _isPreparedToPlay = NO;
    self->_seekTime = 0;
    self->_currentTime = 0;
    self->_totalTime = 0;
    self->_bufferTime = 0;
    self.isReadyToPlay = NO;
    [self changeIsIdleNetworkEnvironment:YES];
}

- (void)seekToTime:(NSTimeInterval)time {
    [self seekToTime:time completionHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler {
    if (self.totalTime > 0) {
        [self pause]; /// 先暂停
        _isSeek = YES;
        int32_t timeScale = _playerItem.asset.duration.timescale;
        CMTime seekTime = CMTimeMakeWithSeconds(time, timeScale);
        [_player seekToTime:seekTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            if (completionHandler) completionHandler(finished);
            if (!self) return;
            if (finished) [self play];
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayerDidSeekEnd:)]) {
                [self.delegate onPlayerManagerPlayerDidSeekEnd:self];
            }
            self.eventType = TPlayerEventSeekEnd;
            self->_seekTime = time;
            self.isSeek = NO;
            [self toEvaluatingNetworkEnvironment];
        }];
    } else {
        _seekTime = time;
    }
}


- (void)enableAudioTracks:(BOOL)enable inPlayerItem:(AVPlayerItem*)playerItem {
    for (AVPlayerItemTrack *track in playerItem.tracks){
        if ([track.assetTrack.mediaType isEqual:AVMediaTypeVideo]) {
            track.enabled = enable;
        }
    }
}

//切换播放源
- (void)switchSource {
    if (!self.urlSource) return;
    if ([self.urlSource.url isEqualToString:_assetURL.absoluteString]) return;
    _assetURL = [NSURL URLWithString:self.urlSource.url];
    _asset = self.urlSource.asset;
    _playerItem = self.urlSource.playerItem;
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    [self enableAudioTracks:YES inPlayerItem:_playerItem];
    
    TAVPlayerPresentView *presentView = (TAVPlayerPresentView *)self.view;
    presentView.player = _player;
    self.scalingMode = _scalingMode;
    
    if (@available(iOS 9.0, *)) {
        _playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = NO;
    }
    if (@available(iOS 10.0, *)) {
//        _playerItem.preferredForwardBufferDuration = 10;
        _player.automaticallyWaitsToMinimizeStalling = NO;
    }
    
    [self itemObserving];
}

//添加监听
- (void)itemObserving {
    /// 移除监听
    [_playerLayerKVO safelyRemoveAllObservers];
    [_playerItemKVO safelyRemoveAllObservers];
    [_playerKVO safelyRemoveAllObservers];
    
    /// 添加首帧显示监听
    TAVPlayerPresentView *presentView = (TAVPlayerPresentView *)self.view;
    _playerLayerKVO = [[TAVKVOController alloc] initWithTarget:[presentView avLayer]];
    [_playerLayerKVO safelyAddObserver:self
                            forKeyPath:kReadyForDisplay
                               options:NSKeyValueObservingOptionNew
                               context:nil];
    
    _playerKVO = [[TAVKVOController alloc] initWithTarget:_player];
    [_playerKVO safelyAddObserver:self
                       forKeyPath:kStatus
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    
    ///一种状态，指示在等待适当的网络条件时是当前正在进行播放，无限期暂停还是暂停播放
    if (@available(iOS 10.0, *)) {
        
        [_playerKVO safelyAddObserver:self
                           forKeyPath:kTimeControlStatus
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    }
    
    /// 添加item监听
    _playerItemKVO = [[TAVKVOController alloc] initWithTarget:_playerItem];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kStatus
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPlaybackBufferEmpty
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPlaybackLikelyToKeepUp
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPlaybackBufferFull
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kLoadedTimeRanges
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    [_playerItemKVO safelyAddObserver:self
                           forKeyPath:kPresentationSize
                              options:NSKeyValueObservingOptionNew
                              context:nil];
    
    CMTime interval = CMTimeMakeWithSeconds(self.timeRefreshInterval > 0 ? self.timeRefreshInterval : 0.1, NSEC_PER_SEC);
    @weakify(self)
    _timeObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        @strongify(self)
        if (!self) {
            return;
        }
        NSArray *loadedRangs = self.playerItem.seekableTimeRanges;
        if (self.isPlaying && self.loadState == TPlayerLoadStateStalled) self.player.rate = self.rate;
        if (loadedRangs.count > 0) {
            #pragma mark — TODO///播放进度改变
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayTimeChanged:currentTime:totalTime:progress:)]) {
                [self.delegate onPlayerManagerPlayTimeChanged:self currentTime:self.currentTime totalTime:self.totalTime progress:self.currentTime / self.totalTime];
            }
        }
        
    }];
    
    _itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self)
        if (!self) return;
        self.eventType = TPlayerEventCompletion;
        #pragma mark — TODO///播放结束
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerDidToFinish:)]) {
            [self.delegate onPlayerManagerDidToFinish:self];
        }
        if (self.loop) {
            AVPlayerItem *item = [note object];
            [item seekToTime:kCMTimeZero];
            [self.player play];
            self.eventType = TPlayerEventLoopingStart;
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayerDidLoopingStart:)]) {
                [self.delegate onPlayerManagerPlayerDidLoopingStart:self];
            }
        }
    }];
    
}

#pragma mark — KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{ ///主线程
        if ([keyPath isEqualToString:kStatus]) {
            [self statusChange];
        } else if ([keyPath isEqualToString:kPlaybackBufferEmpty]) {
            [self playbackBufferEmptyChange];
        } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUp]) {
            [self playbackLikelyToKeepUpChange];
        } else if ([keyPath isEqualToString:kPlaybackBufferFull]) {
            [self playbackBufferFullChange];
        } else if ([keyPath isEqualToString:kLoadedTimeRanges]) {
            [self loadedTimeRangesChange];
        } else if ([keyPath isEqualToString:kPresentationSize]) {
            [self presentationSizeChange];
        } else if ([keyPath isEqualToString:kReadyForDisplay]) {
            [self readyForDisplayChange];
        } else if ([keyPath isEqualToString:kTimeControlStatus]) {
            [self timeControlStatusChange];
        } else {
            [super observeValueForKeyPath:keyPath
                                 ofObject:object
                                   change:change
                                  context:context];
        }
     });
}

#pragma mark — timeControlStatus
- (void)timeControlStatusChange {
    
    if (@available(iOS 10.0, *)) {
        NSString *timeControlStatus = @"";
        switch (self.player.timeControlStatus) {
            case AVPlayerTimeControlStatusPaused:
                timeControlStatus = @"AVPlayerTimeControlStatusPaused";
                break;
          case AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate:
            timeControlStatus = @"AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate";
            break;
            case AVPlayerTimeControlStatusPlaying:
            timeControlStatus = @"AVPlayerTimeControlStatusPlaying";
            break;
            default:
                break;
        }
        
        /// 该方法iOS10 以上才可以使用
        if (self.player.timeControlStatus == AVPlayerTimeControlStatusPaused || self.player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
            if (self.player.reasonForWaitingToPlay == AVPlayerWaitingToMinimizeStallsReason) {
                if ((self.isPlaying || self.isSeek) && self.eventType != TPlayerEventLoadingStart && self.isReadyToPlay) self.eventType = TPlayerEventLoadingStart;
            } else if (self.player.reasonForWaitingToPlay == AVPlayerWaitingWithNoItemToPlayReason || self.player.reasonForWaitingToPlay == AVPlayerWaitingWhileEvaluatingBufferingRateReason) { /// 这种状态下,官方不建议显示加载指示器
                if (self.isPlaying || self.isSeek) self.eventType = TPlayerEventLoadingEnd;
            }
        } else {
            if (self.isPlaying || self.isSeek) self.eventType = TPlayerEventLoadingEnd;
        }
    }
}

#pragma mark — readyForDisplay
- (void)readyForDisplayChange {
    if (self.isReadyToPlay) { /// 准备完成已经回调,再设置首帧显示
        self.eventType = TPlayerEventFirstRenderedStart;
    }
}

#pragma mark ——— status
- (void)statusChange {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay && self.player.status == AVPlayerStatusReadyToPlay) {
        self.loadState = TPlayerLoadStatePlaythroughOK;
        if (!self.isReadyToPlay) {
            self.isReadyToPlay = YES;
            self.eventType = TPlayerEventPrepareDone;
            #pragma mark — TODO///准备播放
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayerDidReadyToPlay:)]) {
                [self.delegate onPlayerManagerPlayerDidReadyToPlay:self];
            }
        }
        if (self.seekTime) {
            if (self.shouldAutoPlay) [self.player pause]; //seek 先暂停,再播放
            [self seekToTime:self.seekTime completionHandler:^(BOOL finished) {
                if (finished) {
                    if (self.shouldAutoPlay) {
                        [self play];
                        self.eventType = TPlayerEventAutoPlayStart;
                    };
                }
            }];
            _seekTime = 0;
        } else {
            if (self.shouldAutoPlay) {
                [self play];
                self.eventType = TPlayerEventAutoPlayStart;
            };
        }
        self.player.muted = self.muted;
        NSArray *loadedRangs = self.playerItem.seekableTimeRanges;
        if (loadedRangs.count > 0) {
            #pragma mark — TODO///播放进度改变
            if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPlayTimeChanged:currentTime:totalTime:progress:)]) {
                [self.delegate onPlayerManagerPlayTimeChanged:self currentTime:self.currentTime totalTime:self.totalTime progress:self.currentTime / self.totalTime];
            }
        }
    } else if (self.player.currentItem.status == AVPlayerItemStatusFailed || self.player.status == AVPlayerStatusFailed) {
        _isPlaying = NO;
        #pragma mark — TODO///播放失败
        TPlayerErrorModel *error = [[TPlayerErrorModel alloc] init];
        error.errorCode = self.player.currentItem.error.code;
        error.errorMessage = self.player.currentItem.error.localizedDescription;
        error.error = self.player.currentItem.error;
        if (self.delegate && [self.delegate respondsToSelector:@selector(onError:errorModel:)]) {
            [self.delegate onError:self errorModel:error];
        }
    }
    [self toEvaluatingStartLoading];
    [self toEvaluatingNetworkEnvironment];
}

#pragma mark ——— loadedTimeRanges
- (void)loadedTimeRangesChange {
    NSTimeInterval bufferTime = [self availableDuration];
    _bufferTime = bufferTime;
    #pragma mark — TODO///缓冲进度变化
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerBufferTimeChanged:bufferTime:totalTime:progress:)]) {
        [self.delegate onPlayerManagerBufferTimeChanged:self bufferTime:bufferTime totalTime:self.totalTime progress:bufferTime / self.totalTime];
    }
}

#pragma mark ——— playbackBufferEmpty
- (void)playbackBufferEmptyChange {
    //当缓存为空
    if (self.playerItem.playbackBufferEmpty) {
        self.loadState = TPlayerLoadStateStalled;
        [self bufferingSomeSecond];
    }
    [self toEvaluatingStartLoading];
}

#pragma mark ——— playbackLikelyToKeepUp
- (void)playbackLikelyToKeepUpChange {
    //当缓存好了
    if (self.playerItem.playbackLikelyToKeepUp) {
        self.loadState = TPlayerLoadStatePlayable;
        if (self.isPlaying) [self.player play];
    }
    [self toEvaluatingStartLoading];

}

#pragma mark — kPlaybackBufferFull
- (void)playbackBufferFullChange {
    //当缓存好了
    if (self.playerItem.playbackBufferFull) {
        self.loadState = TPlayerLoadStatePlayable;
    }
    [self toEvaluatingStartLoading];

}

#pragma mark ——— presentationSize
- (void)presentationSizeChange {
    _presentationSize = self.playerItem.presentationSize;
    #pragma mark — TODO///视频尺寸变化
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerPresentationSizeChanged:presentationSize:)]) {
        [self.delegate onPlayerManagerPresentationSizeChanged:self presentationSize:_presentationSize];
    }
}


#pragma mark - private method
/// 评估是否需要开始loading
- (void)toEvaluatingStartLoading {
    
    if (self.isReadyToPlay && (self.playerItem.playbackBufferFull || self.playerItem.playbackLikelyToKeepUp)) {
        if (self.isPlaying || self.isSeek) self.eventType = TPlayerEventLoadingEnd;
    } else if (self.isReadyToPlay) {
        if ((self.isPlaying || self.isSeek) && self.eventType != TPlayerEventLoadingStart) self.eventType = TPlayerEventLoadingStart;
    }
}

/// 评估当前网络资源是否富足
- (void)toEvaluatingNetworkEnvironment {
    /** 网速
     * 当下载网速为256KB/s左右时，基本达到秒开，但播放后会卡顿
     * 300KB/s 秒开，自动播放大概率卡顿，勉勉强强
     * 当下载网速在500KB/s左右时，开启预加载，秒开，基本不会卡顿
     */
    //处理缓冲完成的情况
    if (_bufferTime != 0) {
        //开始了
        if (_bufferTime == self.totalTime) {
            [self changeIsIdleNetworkEnvironment:YES];
        } else {
            if (_downSpeed <= 256 *1024 && (_bufferTime - self.currentTime) <= 5) {
                //缓冲完成后下载速度为0 需要判断缓冲进度·
                [self changeIsIdleNetworkEnvironment:NO];
            } else {
                [self changeIsIdleNetworkEnvironment:YES];
            }
        }
    }
}

- (void)changeIsIdleNetworkEnvironment:(BOOL)isIdleNetworkEnvironment {
    if (self.isIdleNetworkEnvironment != isIdleNetworkEnvironment) {
        if (isIdleNetworkEnvironment) {
            [self setValue:@YES forKey:@"isIdleNetworkEnvironment"];
        } else {
            [self setValue:@NO forKey:@"isIdleNetworkEnvironment"];
        }
    }
}

- (void)networkSpeedChanged:(NSNotification *)sender {
    _downSpeed = [[sender.userInfo objectForKey:TNetworkSpeedValueNotificationKey] intValue];
    
}

/// 计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *timeRangeArray = _playerItem.loadedTimeRanges;
    CMTime currentTime = [_player currentTime];
    BOOL foundRange = NO;
    CMTimeRange aTimeRange = {0};
    if (timeRangeArray.count) {
        aTimeRange = [[timeRangeArray objectAtIndex:0] CMTimeRangeValue];
        if (CMTimeRangeContainsTime(aTimeRange, currentTime)) {
            foundRange = YES;
        }
    }
    
    if (foundRange) {
        CMTime maxTime = CMTimeRangeGetEnd(aTimeRange);
        NSTimeInterval playableDuration = CMTimeGetSeconds(maxTime);
        if (playableDuration > 0) {
            return playableDuration;
        }
    }
    return 0;
}

/**
 *  缓冲较差时候回调这里
 */
- (void)bufferingSomeSecond {
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    if (self.isBuffering || !self.isPlaying) return;
    /// 没有网络
    if (![[ZEBReachability reachabilityForInternetConnection] isReachable]) return;
    self.isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (!self.isPlaying && (self.loadState == TPlayerLoadStateStalled || self.loadState == TPlayerLoadStateUnknown)) {
            self.isBuffering = NO;
            return;
        }
        [self play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        self.isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) [self bufferingSomeSecond];
    });
}

#pragma mark — setter/getter
//内容显示的view
- (TPlayerView *)view {
    if (!_view) {
        _view = [[TAVPlayerPresentView alloc] init];
    }
    return _view;
}

//配置URL资源
- (void)setUrlSource:(TPlayerUrlSource *)urlSource {
    _urlSource = urlSource;
    if (_isPlaying) [self stop]; // 正在播放先暂停
    [self play];
}

//设置显示的view
- (void)setPlayerView:(UIView *)playerView {
    
    if (playerView) {
        self.view.frame = playerView.bounds;
        self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [playerView addSubview:self.view];
    } else {
        [self.view removeFromSuperview];
    }
}

- (void)setEventType:(TPlayerEventType)eventType {
    _eventType = eventType;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerEvent:eventType:)]) {
        [self.delegate onPlayerManagerEvent:self eventType:eventType];
    }
}

- (void)setLoadState:(TPlayerLoadState)loadState {
    _loadState = loadState;
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayerManagerLoad:loadState:)]) {
        [self.delegate onPlayerManagerLoad:self loadState:loadState];
    }
}

//设置内容模式
- (void)setScalingMode:(TPlayerPlayerScalingMode)scalingMode {
    _scalingMode = scalingMode;
     TAVPlayerPresentView *presentView = (TAVPlayerPresentView *)self.view;
    switch (scalingMode) {
        case TPlayerPlayerScalingModeNone:
            presentView.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
       case TPlayerPlayerScalingModeAspectFit:
            presentView.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case TPlayerPlayerScalingModeAspectFill:
            presentView.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case TPlayerPlayerScalingModeFill:
            presentView.videoGravity = AVLayerVideoGravityResize;
            break;
        default: {
            
        }
            break;
    }
}

- (void)setRate:(float)rate {
    _rate = rate;
    if (self.player && fabsf(_player.rate) > 0.00001f) {
        self.player.rate = rate;
    }
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    self.player.muted = muted;
}

- (void)setVolume:(float)volume {
    _volume = MIN(MAX(0, volume), 1);
    self.player.volume = volume;
}

- (float)rate {
    return _rate == 0 ? 1 : _rate;
}

- (NSTimeInterval)totalTime {
    NSTimeInterval sec = CMTimeGetSeconds(self.player.currentItem.duration);
    if (isnan(sec)) {
        return 0;
    }
    return sec;
}

- (NSTimeInterval)currentTime {
    NSTimeInterval sec = CMTimeGetSeconds(self.playerItem.currentTime);
    if (isnan(sec) || sec < 0) {
        return 0;
    }
    return sec;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

