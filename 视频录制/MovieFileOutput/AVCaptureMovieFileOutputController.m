//
//  AVCaptureMovieFileOutputController.m
//  视频录制
//
//  Created by 王景伟 on 2020/9/21.
//  Copyright © 2020 王景伟. All rights reserved.
//  如果单纯的使用AVCaptureMovieFileOutput将录制的视频文件进行输出，则会导致录制的视频文件太过于大

#import "AVCaptureMovieFileOutputController.h"
#import "MovieFileOutputView.h"
#import <AVFoundation/AVFoundation.h>

@interface AVCaptureMovieFileOutputController ()<MovieFileOutputViewDelegate>
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) MovieFileOutputView *recordView;
@property (nonatomic, strong) AVPlayer *player;
@end

@implementation AVCaptureMovieFileOutputController

- (void)dealloc {
    [self.recordView stopRunning];
    NSLog(@"%s",__func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createView];
}


- (void)createView {
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.recordView = [[MovieFileOutputView alloc]initWithFrame:CGRectMake(100, 100, 200, 200)];
    self.recordView.delegate = self;
    [self.view addSubview:self.recordView];
    
    [self.recordView startRunning];
    
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"开始" forState:0];
    [self.startButton setTitle:@"结束" forState:UIControlStateSelected];
    self.startButton.frame = CGRectMake(50, 50, 100, 50);
    [self.view addSubview:self.startButton];
    [self.startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
}

- (void)startAction {
    self.startButton.selected = !self.startButton.isSelected;
    
    if (self.startButton.isSelected) {
        [self.recordView startCapture];
    } else {
        [self.recordView stopCapture];
    }
}

- (void)playbackFinished:(NSNotification *)notification {
    [self.player pause];
    self.player = nil;
}

/// 开始录制
- (void)uploadIntroRecordViewDidStartRecording {
    
}
/// 录制完成回调
- (void)uploadIntroRecordViewDidFinishRecordingToOutputFile:(NSURL *)url imageCover:(UIImage *)imageCover {
    self.player = [AVPlayer playerWithURL:url];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = CGRectMake(100, 350, 200, 200);
    [self.view.layer addSublayer:playerLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [self.player play];
}
@end
