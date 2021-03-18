//
//  TPlayerErrorModel.h
//  timingapp
//
//  Created by enbin zhang on 2020/7/3.
//  Copyright © 2020 huiian. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TPlayerErrorModel : NSObject

/** 错误码 */
@property (nonatomic, assign) NSInteger errorCode;
/** 错误信息 */
@property (nonatomic, copy) NSString *errorMessage;
/** 错误 */
@property (nonatomic, strong) NSError *error;

@end

NS_ASSUME_NONNULL_END
