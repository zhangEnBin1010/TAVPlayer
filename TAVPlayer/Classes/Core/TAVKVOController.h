//
//  TAVKVOController.h
//  timingapp
//
//  Created by enbin zhang on 2020/7/3.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TAVKVOController : NSObject

- (instancetype)initWithTarget:(NSObject *)target;

- (void)safelyAddObserver:(nonnull NSObject *)observer
               forKeyPath:(nonnull NSString *)keyPath
                  options:(NSKeyValueObservingOptions)options
                  context:(nullable void *)context;
- (void)safelyRemoveObserver:(nonnull NSObject *)observer
                  forKeyPath:(nullable NSString *)keyPath;

- (void)safelyRemoveAllObservers;

@end

NS_ASSUME_NONNULL_END
