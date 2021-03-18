//
//  TSliderView.h
//  timingapp
//
//  Created by enbin zhang on 2020/8/18.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TSliderView;

NS_ASSUME_NONNULL_BEGIN

@protocol TSliderViewDelegate <NSObject>

@optional
// 滑块滑动开始
- (void)sliderViewDidTouchBegan:(TSliderView *)sliderView value:(float)value;
// 滑块滑动中
- (void)sliderViewDidValueChanged:(TSliderView *)sliderView value:(float)value;
// 滑块滑动结束
- (void)sliderViewDidTouchEnded:(TSliderView *)sliderView value:(float)value;
// 滑杆点击
- (void)sliderViewDidTapped:(TSliderView *)sliderView value:(float)value;

@end

@interface TSliderButton : UIButton

@end


@interface TSliderView : UIView


@property (nonatomic, weak) id<TSliderViewDelegate> delegate;

/** 滑块 */
@property (nonatomic, strong, readonly) TSliderButton *sliderBtn;

/** 默认滑杆的颜色 */
@property (nonatomic, strong) UIColor *maximumTrackTintColor;

/** 滑杆进度颜色 */
@property (nonatomic, strong) UIColor *minimumTrackTintColor;

/** 缓存进度颜色 */
@property (nonatomic, strong) UIColor *bufferTrackTintColor;

/** loading进度颜色 */
@property (nonatomic, strong) UIColor *loadingTintColor;

/** 默认滑杆的图片 */
@property (nonatomic, strong) UIImage *maximumTrackImage;

/** 滑杆进度的图片 */
@property (nonatomic, strong) UIImage *minimumTrackImage;

/** 缓存进度的图片 */
@property (nonatomic, strong) UIImage *bufferTrackImage;

/** 滑杆进度 */
@property (nonatomic, assign) float value;

/** 缓存进度 */
@property (nonatomic, assign) float bufferValue;

/** 是否允许点击，默认是YES */
@property (nonatomic, assign) BOOL allowTapped;

/** 是否允许点击，默认是YES */
@property (nonatomic, assign) BOOL animate;

/** 设置滑杆的高度 */
@property (nonatomic, assign) CGFloat sliderHeight;

/** 设置滑杆的圆角 */
@property (nonatomic, assign) CGFloat sliderRadius;

/** 是否隐藏滑块（默认为NO） */
@property (nonatomic, assign) BOOL isHideSliderBlock;

/// 是否正在拖动
@property (nonatomic, assign) BOOL isdragging;

/// 向前还是向后拖动
@property (nonatomic, assign) BOOL isForward;

@property (nonatomic, assign) CGSize thumbSize;

/**
 *  Starts animation of the spinner.
 */
- (void)startAnimating;

/**
 *  Stops animation of the spinnner.
 */
- (void)stopAnimating;

// 设置滑块背景色
- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state;

// 设置滑块图片
- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state;

@end

@interface UIView (TZEB)

@property (nonatomic) CGFloat zeb_left;

/**
 * Shortcut for frame.origin.y
 *
 * Sets frame.origin.y = top
 */
@property (nonatomic) CGFloat zeb_top;

/**
 * Shortcut for frame.origin.x + frame.size.width
 *
 * Sets frame.origin.x = right - frame.size.width
 */
@property (nonatomic) CGFloat zeb_right;

/**
 * Shortcut for frame.origin.y + frame.size.height
 *
 * Sets frame.origin.y = bottom - frame.size.height
 */
@property (nonatomic) CGFloat zeb_bottom;

/**
 * Shortcut for frame.size.width
 *
 * Sets frame.size.width = width
 */
@property (nonatomic) CGFloat zeb_width;

/**
 * Shortcut for frame.size.height
 *
 * Sets frame.size.height = height
 */
@property (nonatomic) CGFloat zeb_height;

/**
 * Shortcut for center.x
 *
 * Sets center.x = centerX
 */
@property (nonatomic) CGFloat zeb_centerX;

/**
 * Shortcut for center.y
 *
 * Sets center.y = centerY
 */
@property (nonatomic) CGFloat zeb_centerY;
/**
 * Shortcut for frame.origin
 */
@property (nonatomic) CGPoint zeb_origin;

/**
 * Shortcut for frame.size
 */
@property (nonatomic) CGSize zeb_size;


@end


NS_ASSUME_NONNULL_END
