//
//  ZEBViewController.m
//  TAVPlayer
//
//  Created by zhangEnBin1010 on 03/18/2021.
//  Copyright (c) 2021 zhangEnBin1010. All rights reserved.
//

#import "ZEBViewController.h"
#import <TAVPlayer.h>

@interface ZEBViewController ()

@property (nonatomic, strong) UIView *viewPlayer;

/** 播放器管理类 */
@property (nonatomic, strong) id<TPlayerMediaPlayback> playerManager;

@end

@implementation ZEBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.playerManager = [TAVPlayerManager manager];
    
    
    self.viewPlayer = [[UIView alloc] initWithFrame:CGRectMake(0, 80, UIScreen.mainScreen.bounds.size.width, 250)];
    self.viewPlayer.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.viewPlayer];
    
    [self.playerManager setPlayerView:self.viewPlayer];
    
    TPlayerUrlSource *urlSource = [[TPlayerUrlSource alloc] initWithUrlWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" requestHeader:nil];
    [self.playerManager setUrlSource:urlSource];
    [self.playerManager play];
    [self.playerManager setLoop:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
