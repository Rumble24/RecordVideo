//
//  BeautyController.m
//  视频录制
//
//  Created by 王景伟 on 2020/9/22.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "BeautyController.h"
#import <GPUImage/GPUImage.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "GPUImageCropFilter.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface BeautyController ()<GPUImageVideoCameraDelegate>

///< 创建摄像头
@property (nonatomic, strong) GPUImageVideoCamera *camera;
///< 创建展示的view  视频播放器的实现
@property (nonatomic, strong) GPUImageView *previewLayer;

                                           /// GPUImageFilter  需要我们写各种shader[着色器] 处理每一个像素点
///大致流程     输出源<GPUImageOutput>   -->   处理<GPUImageOutput 和 GPUImageInput>   -->   处理后的视频/图片<GPUImageInput>



///< 采用视频链的方式第一个处理完 再处理第二个 GPU处理链

///< 创建几个滤镜。我们可以基于 GPUImageFilter 写自己的滤镜
///< 大量现成的内置滤镜（4大类） 1). 颜色类（亮度、色度、饱和度、对比度、曲线、白平衡...） 2). 图像类（仿射变换、裁剪、高斯模糊、毛玻璃效果...） 3). 颜色混合类（差异混合、alpha混合、遮罩混合...） 4). 效果类（像素化、素描效果、压花效果、球形玻璃效果...）


///< 摩皮
@property (nonatomic, strong) GPUImageBilateralFilter *bilaterFilter;
///< 曝光
@property (nonatomic, strong) GPUImageExposureFilter *exposureFilter;
///< 美白
@property (nonatomic, strong) GPUImageBrightnessFilter *brigtnessFilter;
///< 饱和
@property (nonatomic, strong) GPUImageSaturationFilter *saturationFilter;
///< 裁剪
@property (nonatomic, strong) GPUImageCropFilter *cropFilter;
///< 创建写入的文件
@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic,   copy) NSString *moviePath;

///< 开始/结束
@property (nonatomic, strong) UIButton *startButton;
///< 播放
@property (nonatomic, strong) UIButton *playBtn;
///< 切换摄像头
@property (nonatomic, strong) UIButton *switchCameraBtn;
///< 开关
@property (nonatomic, strong) UISwitch *beautyBtn;
///< 磨皮
@property (nonatomic, strong) UISlider *mopiSlider;
///< 曝光
@property (nonatomic, strong) UISlider *baoguangSlider;
///< 美白
@property (nonatomic, strong) UISlider *meibaiSlider;
///< 饱和
@property (nonatomic, strong) UISlider *baoheSlider;

@property (nonatomic, assign) CGSize writerSize;

@property (nonatomic, assign) CGRect cropRegion;

/// 默认 1 ： 1
@property (nonatomic, assign) HDVideoAspectRatio ratio;
@end
@implementation BeautyController

- (instancetype)initWithAspectRatio:(HDVideoAspectRatio)ratio {
    if (self = [super init]) {
        self.ratio = ratio;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createViews];
    
    [self startCapture];
}

- (void)createViews {
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.playBtn];
    [self.view addSubview:self.startButton];
    [self.view addSubview:self.switchCameraBtn];
    [self.view addSubview:self.beautyBtn];
    [self.view addSubview:self.mopiSlider];
    [self.view addSubview:self.baoguangSlider];
    [self.view addSubview:self.meibaiSlider];
    [self.view addSubview:self.baoheSlider];
}

/*
 /// 3:4
 HD_VIDEO_RATIO_3_4,
 /// 9:16
 HD_VIDEO_RATIO_9_16,
 */
- (void)setRatio:(HDVideoAspectRatio)ratio {
    _ratio = ratio;
    
    self.cropRegion = CGRectMake(0, 0, 1, 1);
    CGFloat radio = 1;
    if (ratio == HD_VIDEO_RATIO_3_4) {
        self.camera.captureSessionPreset = AVCaptureSessionPreset1280x720;
        radio = 3 / 4.f;
        CGFloat space = 1 - (3 * 3) / (4.0 * 4); // 竖直方向应该裁剪掉的空间
        self.cropRegion = CGRectMake(0, space / 2, 1, 1 - space);
    } else if (ratio == HD_VIDEO_RATIO_9_16) {
        self.camera.captureSessionPreset = AVCaptureSessionPreset1280x720;
        radio = 9 / 16.f;
        CGFloat space = 1 - (9 * 9) / (16.0 * 16); // 竖直方向应该裁剪掉的空间
        self.cropRegion = CGRectMake(0, space / 2, 1, 1 - space);
    } else if (ratio == HD_VIDEO_RATIO_1_1) {
        self.camera.captureSessionPreset = AVCaptureSessionPreset640x480;
        CGFloat space = (4 - 3) / 4.0; // 竖直方向应该裁剪掉的空间
        self.cropRegion = CGRectMake(0, space / 2, 1, 1 - space);
    } else if (ratio == HD_VIDEO_RATIO_4_3) {
        radio = 4 / 3.f;
        self.camera.captureSessionPreset = AVCaptureSessionPreset640x480;
    } else if (ratio == HD_VIDEO_RATIO_16_9) {
        radio = 16 / 9.f;
        self.camera.captureSessionPreset = AVCaptureSessionPreset1280x720;
    } else if (ratio == HD_VIDEO_RATIO_FULL) {
        self.camera.captureSessionPreset = AVCaptureSessionPreset1280x720;
        CGFloat currentRatio = kScreenHeight / kScreenWidth;
        radio = currentRatio;
        if (currentRatio > 16.0 / 9.0) { // 需要在水平方向裁剪
            CGFloat resultWidth = 16.0 / currentRatio;
            CGFloat space = (9.0 - resultWidth) / 9.0;
            self.cropRegion = CGRectMake(space / 2, 0, 1 - space, 1);
        } else { // 需要在竖直方向裁剪
            CGFloat resultHeight = 9.0 * currentRatio;
            CGFloat space = (16.0 - resultHeight) / 16.0;
            self.cropRegion = CGRectMake(0, space / 2, 1, 1 - space);
        }
    }
    self.writerSize = CGSizeMake(kScreenWidth, kScreenWidth * radio);
    
    NSLog(@"%@",NSStringFromCGRect(self.cropRegion));
}

/**
 获取缓存的路径

 @return 获取到自己想要的url
 */
- (NSURL *)obtainUrl{
  
    NSString *pathStr = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"456.mp4"];
    self.moviePath = pathStr;
    // 判断路径是否存在
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathStr]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathStr error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    return url;
}
/**
 创建过滤组
 */
- (GPUImageFilterGroup *)obtainFilterGroup {
    
    GPUImageFilterGroup *group = [[GPUImageFilterGroup alloc] init];
    // 按照顺序组成一个链
    [self.bilaterFilter addTarget:self.exposureFilter];
    [self.exposureFilter addTarget:self.brigtnessFilter];
    [self.brigtnessFilter addTarget:self.saturationFilter];
    [self.saturationFilter addTarget:self.cropFilter];

    // 将滤镜添加到滤镜组中(开始和结尾)
    group.initialFilters = @[self.bilaterFilter];
    group.terminalFilter = self.cropFilter;
    
    return group;
}



#pragma mark - 相关按钮的点击事件
/// 开始录制
- (void)startCapture {
    
    if (CGRectEqualToRect(self.cropRegion, CGRectZero) ) {
        self.ratio = HD_VIDEO_RATIO_1_1;
    }
    
    //初始化一些滤镜
    self.bilaterFilter = [[GPUImageBilateralFilter alloc] init];
    self.exposureFilter = [[GPUImageExposureFilter alloc] init];
    self.brigtnessFilter = [[GPUImageBrightnessFilter alloc] init];
    self.saturationFilter = [[GPUImageSaturationFilter alloc] init];
    
    self.cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:self.cropRegion];

    
    self.mopiSlider.value = self.bilaterFilter.distanceNormalizationFactor / 10.f;
    self.baoguangSlider.value = self.exposureFilter.exposure;
    self.meibaiSlider.value = self.brigtnessFilter.brightness + 0.5;
    self.baoheSlider.value = self.saturationFilter.saturation;
    
    // 调整摄像头的方向
    self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    // 调整摄像头的镜像 自己动的方向和镜子中的方向一致
    self.camera.horizontallyMirrorFrontFacingCamera = YES;
    // 创建过滤层
    GPUImageFilterGroup *filterGroup = [self obtainFilterGroup];
    [self.camera addTarget:filterGroup];
    // 将imageview 添加到过滤层上
    [filterGroup addTarget:self.previewLayer];
    
    [self.view insertSubview:self.previewLayer atIndex:0];
    // 开始拍摄
    [self.camera startCameraCapture];
#pragma mark - 开始写入视频
    self.movieWriter.encodingLiveVideo = YES;
    [filterGroup addTarget:self.movieWriter];
    self.camera.delegate = self;
    self.camera.audioEncodingTarget = self.movieWriter;
    // 开始录制
    [self.movieWriter startRecording];
}

/** 结束直播相关的事件 */
- (void)endLiveAction:(UIButton *)sender {
    [self.camera stopCameraCapture];
    [self.previewLayer removeFromSuperview];
    [self.movieWriter finishRecording];
}
/** 开始播放视频 */
- (void)startPlayAction:(UIButton *)sender {
    self.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.moviePath]];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    playerLayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [self.view.layer addSublayer:playerLayer];
    [self.player play];
    
    
    //获取视频尺寸
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.moviePath]];
    NSArray *array = asset.tracks;
    CGSize videoSize = CGSizeZero;
    
    for (AVAssetTrack *track in array) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            videoSize = track.naturalSize;
        }
    }
    NSLog(@"startPlayAction : %@",NSStringFromCGSize(videoSize));
}
/** 切换前后摄像头 */
- (void)switchFontAndBehindCameraAction:(UIButton *)sender {
    [self.camera rotateCamera];
}

/** 开启或者关闭美颜 */
- (void)closeOrOpenBeautifulAction:(UISwitch *)sender {
    if (sender.isOn) {
        [self.camera removeAllTargets];
        GPUImageFilterGroup *group = [self obtainFilterGroup];
        [self.camera addTarget:group];
        [group addTarget:self.previewLayer];
        
    } else {
        [self.camera removeAllTargets];
        [self.camera addTarget:self.previewLayer];
    }
}

/** 磨皮的slider的事件 */
- (void)mopiSliderAction:(UISlider *)sender {
    self.bilaterFilter.distanceNormalizationFactor = sender.value * 10;
}
/** 曝光的按钮的点击事件 */
- (void)baoguangSliderAction:(UISlider *)sender {
    self.exposureFilter.exposure = sender.value;
}
/** 美白的按钮的点击事件 */
- (void)meibaiSliderAction:(UISlider *)sender {
    self.brigtnessFilter.brightness = (sender.value - 0.5) / 10.f;
}
/** 饱和的按钮的点击事件 */
- (void)baoheSliderAction:(UISlider *)sender {
    self.saturationFilter.saturation = sender.value;
}


#pragma mark - camera 的 delegate
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    
}

/// 设置录制的宽高 startRunning 前调用
- (void)setAspectRatio:(HDVideoAspectRatio)videoRatio {
    
}

#pragma mark - 懒加载
- (GPUImageVideoCamera *)camera {
    if (!_camera) {
        _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    }
    return _camera;
}
- (GPUImageView *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenWidth)];
        _previewLayer.fillMode = kGPUImageFillModePreserveAspectRatio;
    }
    return _previewLayer;
}
- (GPUImageMovieWriter *)movieWriter {
    if (!_movieWriter) {
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[self obtainUrl] size:self.writerSize];
    }
    return _movieWriter;
}

////// -- 按钮

///< 开始/结束
- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_startButton setTitle:@"结束" forState:0];
        _startButton.frame = CGRectMake(0, kScreenWidth + 20, kScreenWidth/4.0, 50);
        [_startButton addTarget:self action:@selector(endLiveAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startButton;
}
///< 播放
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_playBtn setTitle:@"播放" forState:0];
        _playBtn.frame = CGRectMake(kScreenWidth/4.0, kScreenWidth + 20, kScreenWidth/4.0, 50);
        [_playBtn setTitleColor:[UIColor redColor] forState:0];
        [_playBtn addTarget:self action:@selector(startPlayAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}
///< 切换摄像头
- (UIButton *)switchCameraBtn {
    if (!_switchCameraBtn) {
        _switchCameraBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_switchCameraBtn setTitle:@"切换摄像头" forState:0];
        _switchCameraBtn.frame = CGRectMake(kScreenWidth/4.0 * 2, kScreenWidth + 20, kScreenWidth/4.0, 50);
        [_switchCameraBtn addTarget:self action:@selector(switchFontAndBehindCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraBtn;
}
///< 开关
- (UISwitch *)beautyBtn {
    if (!_beautyBtn) {
        _beautyBtn = [[UISwitch alloc]initWithFrame:CGRectMake(kScreenWidth/4.0 * 3, kScreenWidth + 20, kScreenWidth/4.0, 50)];
        _beautyBtn.on = YES;
        [_beautyBtn addTarget:self action:@selector(closeOrOpenBeautifulAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _beautyBtn;
}
///< 磨皮
- (UISlider *)mopiSlider {
    if (!_mopiSlider) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, kScreenWidth + 100, 80, 50)];
        label.textColor = [UIColor blueColor];
        label.text = @"磨皮";
        label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:label];
        _mopiSlider = [[UISlider alloc]initWithFrame:CGRectMake(90, kScreenWidth + 100, kScreenWidth - 100, 50)];
        [_mopiSlider addTarget:self action:@selector(mopiSliderAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mopiSlider;
}
///< 曝光
- (UISlider *)baoguangSlider {
    if (!_baoguangSlider) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, kScreenWidth + 150, 80, 50)];
        label.textColor = [UIColor blueColor];
        label.text = @"曝光";
        label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:label];
        _baoguangSlider = [[UISlider alloc]initWithFrame:CGRectMake(90, kScreenWidth + 150, kScreenWidth - 100, 50)];
        [_baoguangSlider addTarget:self action:@selector(baoguangSliderAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _baoguangSlider;
}
///< 美白
- (UISlider *)meibaiSlider {
    if (!_meibaiSlider) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, kScreenWidth + 200, 80, 50)];
        label.textColor = [UIColor blueColor];
        label.text = @"美白";
        label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:label];
        _meibaiSlider = [[UISlider alloc]initWithFrame:CGRectMake(90, kScreenWidth + 200, kScreenWidth - 100, 50)];
        [_meibaiSlider addTarget:self action:@selector(meibaiSliderAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _meibaiSlider;
}
///< 饱和
- (UISlider *)baoheSlider {
    if (!_baoheSlider) {
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, kScreenWidth + 250, 80, 50)];
        label.textColor = [UIColor blueColor];
        label.text = @"饱和";
        label.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:label];
        _baoheSlider = [[UISlider alloc]initWithFrame:CGRectMake(90, kScreenWidth + 250, kScreenWidth - 100, 50)];
        [_baoheSlider addTarget:self action:@selector(baoheSliderAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _baoheSlider;
}
@end
