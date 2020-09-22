//
//  AVAssetWriterController.m
//  视频录制
//
//  Created by 王景伟 on 2020/9/21.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "AVAssetWriterController.h"
#import "HDUploadIntroRecordView.h"

@interface AVAssetWriterController ()<HDUploadIntroRecordViewDelegate>
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) HDUploadIntroRecordView *recordView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSString *outputFielPath;
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation AVAssetWriterController

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

    self.recordView = [[HDUploadIntroRecordView alloc]initWithFrame:CGRectMake(100, 100, 200, 200)];
    [self.recordView setAspectRatio:HD_VIDEO_RATIO_9_16];
    self.recordView.delegate = self;
    [self.view addSubview:self.recordView];
    
    [self.recordView startRunning];
    
    
    self.startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.startButton setTitle:@"开始" forState:0];
    [self.startButton setTitle:@"结束" forState:UIControlStateSelected];
    self.startButton.frame = CGRectMake(50, 50, 100, 50);
    [self.view addSubview:self.startButton];
    [self.startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.playBtn setTitle:@"播放" forState:0];
    self.playBtn.frame = CGRectMake(200, 50, 100, 50);
    [self.playBtn setTitleColor:[UIColor redColor] forState:0];
    [self.view addSubview:self.playBtn];
    [self.playBtn addTarget:self action:@selector(playAction) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(20, 100, 50, 50)];
    [self.view addSubview:self.imageView];
}

- (void)startAction {
    self.startButton.selected = !self.startButton.isSelected;
    
    if (self.startButton.isSelected) {
        [self.recordView startCapture];
    } else {
        [self.recordView stopCapture];
    }
}

- (void)playAction {
    

}
- (void)playbackFinished:(NSNotification *)notification {
    [self.player pause];
    self.player = nil;
}

/// 开始录制
- (void)uploadIntroRecordViewDidStartRecording {
    
}
/// 录制的进度百分比
- (void)uploadIntroRecordViewProgress:(CGFloat)progress {
    NSLog(@"uploadIntroRecordViewProgress  %f",progress);
}

/// 录制失败
- (void)uploadIntroRecordViewFailWithReason:(NSString *)reason {
    
}
/// 录制完成回调
- (void)uploadIntroRecordViewDidFinishRecordingToAsset:(AVURLAsset *)asset imageCover:(UIImage *)imageCover {
    self.player = [AVPlayer playerWithURL:asset.URL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = CGRectMake(100, 350, 200, 200);
    [self.view.layer addSublayer:playerLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    [self.player play];
    
    self.imageView.image = imageCover;
}

@end
