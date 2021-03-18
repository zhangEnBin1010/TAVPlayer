//
//  TPlayerUrlSource.m
//  timingapp
//
//  Created by enbin zhang on 2020/7/5.
//  Copyright © 2020 huiian. All rights reserved.
//

#import "TPlayerUrlSource.h"

@implementation TPlayerUrlSource

- (instancetype)initWithUrlWithString:(NSString *)url requestHeader:(nullable NSDictionary *)requestHeader {
    self = [super init];
    if (self) {
        _url = url;
        _requestHeader = requestHeader;
        [self config];
    }
    return self;
}

- (instancetype)initWithFileURLWithPath:(NSString *)url {
    self = [super init];
    if (self) {
        _url = url;
        [self config];
    }
    return self;
}

- (void)config {
    
    _asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:_url] options:_requestHeader];
    _playerItem = [AVPlayerItem playerItemWithAsset:_asset];
    
    
}

@end
