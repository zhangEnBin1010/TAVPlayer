//
//  TAVPlayerPlayStatusDefines.h
//  timingapp
//
//  Created by enbin zhang on 2020/8/20.
//  Copyright © 2020 huiian. All rights reserved.
//

#ifndef TAVPlayerPlayStatusDefines_h
#define TAVPlayerPlayStatusDefines_h

/**@brief 播放器事件类型*/
typedef enum TPlayerEventType: NSUInteger {
    /**@brief 准备完成事件*/
    TPlayerEventPrepareDone,
    /**@brief 自动启播事件*/
    TPlayerEventAutoPlayStart,
    /**@brief 首帧显示时间*/
    TPlayerEventFirstRenderedStart,
    /**@brief 播放完成事件*/
    TPlayerEventCompletion,
    /**@brief 缓冲开始事件*/
    TPlayerEventLoadingStart,
    /**@brief 缓冲完成事件*/
    TPlayerEventLoadingEnd,
    /**@brief 跳转完成事件*/
    TPlayerEventSeekEnd,
    /**@brief 循环播放开始事件*/
    TPlayerEventLoopingStart,
} TPlayerEventType;

//加载状态
typedef NS_OPTIONS(NSUInteger, TPlayerLoadState) {
    TPlayerLoadStateUnknown                      = 0,
    TPlayerLoadStatePrepareing                   = 1 << 0, //准备中
    TPlayerLoadStatePlayable                     = 1 << 1, //缓存完成,缓存的数据足够播放
    TPlayerLoadStatePlaythroughOK                = 1 << 3, // 播放器准备好播放,这个状态达到播放器播放要求
    TPlayerLoadStateStalled                      = 1 << 4, // 没有缓存,这种状态下，如果播放，将自动暂停
};

//内容拉伸模式
typedef NS_ENUM(NSInteger, TPlayerPlayerScalingMode) {
    //AVLayerVideoGravityResizeAspect,是按原视频比例显示，是竖屏的就显示出竖屏的，两边留黑
    TPlayerPlayerScalingModeNone,
    //AVLayerVideoGravityResizeAspect,是按原视频比例显示，是竖屏的就显示出竖屏的，两边留黑
    TPlayerPlayerScalingModeAspectFit,
    //AVLayerVideoGravityResizeAspectFill,是以原比例拉伸视频，直到两边屏幕都占满，但视频内容有部分就被切割了
    TPlayerPlayerScalingModeAspectFill,
    //AVLayerVideoGravityResize,是拉伸视频内容达到边框占满，但不按原比例拉伸，这里明显可以看出宽度被拉伸了
    TPlayerPlayerScalingModeFill
};


/**
 弱引用/强引用
 
 Example:
     @weakify(self)
     [self doSomething^{
         @strongify(self)
         if (!self) return;
         ...
     }];
 
 */
#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
            #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
            #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
            #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
            #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
            #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
            #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

#endif /* TAVPlayerPlayStatusDefines_h */
