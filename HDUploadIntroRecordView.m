//
//  HDUploadIntroRecordView.m
//  yanxishe
//
//  Created by 王景伟 on 2020/9/9.
//  Copyright © 2020 hundun. All rights reserved.
//  调研那么久。发现 只有一个实现了改变视频大小：https://github.com/gaoyuexit/WeChatSightDemo
//  https://github.com/XiaoDongXie1024/Crop-sample-buffer  这个人说他也实现了。但是我发现写入本地[_videoInput appendSampleBuffer:sampleBuffer];报错

#import "HDUploadIntroRecordView.h"
#import <Photos/Photos.h>
#import "HDUploadRecordEncoder.h"

@interface HDUploadIntroRecordView ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) HDUploadRecordEncoder *recordEncoder;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property (nonatomic, strong) AVCaptureSession *recordSession;//捕获视频的会话

@property (nonatomic, strong) AVCaptureDevice *videoDevice; //输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;//后置摄像头输入
@property (nonatomic, strong) AVCaptureConnection *videoConnection;//视频录制连接
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;//视频输出

@property (nonatomic, strong) AVCaptureDeviceInput *audioMicInput;//麦克风输入
@property (nonatomic, strong) AVCaptureConnection *audioConnection;//音频录制连接
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;//音频输出

@property (nonatomic, assign) CMTime startTime;//开始录制的时间
@property (nonatomic, assign) BOOL isCapturing;//正在录制
@property (nonatomic, assign) CGFloat currentRecordTime;//当前录制时间


@property (nonatomic, assign) AVCaptureDevicePosition position; //设置焦点
@property (nonatomic, copy) NSString *videoPath;//视频路径

@end

@implementation HDUploadIntroRecordView

- (void)dealloc {
    [_recordSession stopRunning];
    _recordSession = nil;
    _previewLayer = nil;
    _videoInput = nil;
    _audioOutput = nil;
    _videoOutput = nil;
    _audioConnection = nil;
    _videoConnection = nil;
    _recordEncoder = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.maxRecordTime = 10;
    
    self.layer.masksToBounds = YES;
    
    [self.layer insertSublayer:self.previewLayer atIndex:0];
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.bounds;
}


#pragma mark - 公开的方法
/// 开始运行
- (void)startRunning {
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    [self.recordSession startRunning];
}

/// 停止运行
- (void)stopRunning {
    _startTime = CMTimeMake(0, 0);
    if (_recordSession) {
        [_recordSession stopRunning];
    }
    [_recordEncoder finishWithCompletionHandler:^{
    }];
}

/// 开始录制
- (void)startCapture {
    //限制在一个线程执行
    @synchronized(self) {
        if (!self.isCapturing) {
            self.recordEncoder = nil;
            self.isCapturing = YES;
        }
    }
}

/// 停止录制
- (void)stopCapture {
    [self stopCaptureHandler:^(AVURLAsset *asset, UIImage *movieImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (asset == nil || movieImage == nil) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewFailWithReason:)]) {
                    [self.delegate uploadIntroRecordViewFailWithReason:@"录制失败"];
                }
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewDidFinishRecordingToOutputFile:imageCover:)]) {
                    [self.delegate uploadIntroRecordViewDidFinishRecordingToOutputFile:asset imageCover:movieImage];
                }
            }
        });
    }];
}

/// 停止录制
- (void)stopCaptureHandler:(void (^)(AVURLAsset *asset,UIImage *movieImage))handler {
    @synchronized(self) {
        if (self.isCapturing) {
            NSString *path = self.recordEncoder.path;
            self.isCapturing = NO;
            dispatch_queue_t audioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
            dispatch_async(audioQueue, ^{
                [self.recordEncoder finishWithCompletionHandler:^{
                    self.isCapturing = NO;
                    self.recordEncoder = nil;
                    self.startTime = CMTimeMake(0, 0);
                    self.currentRecordTime = 0;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewProgress:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate uploadIntroRecordViewProgress:self.currentRecordTime / self.maxRecordTime];
                        });
                    }
                    //NSURL *url = [NSURL fileURLWithPath:path];
                    //[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    //    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
                    //} completionHandler:^(BOOL success, NSError * _Nullable error) {
                    //    NSLog(@"保存成功");
                    //}];
                    [self movieToImageHandler:handler];
                }];
            });
        }
    }
}

/**
 获取视频第一帧的图片
 */
- (void)movieToImageHandler:(void (^)(AVURLAsset *asset,UIImage *movieImage))handler {
    NSURL *url = [NSURL fileURLWithPath:self.videoPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = TRUE;
    CMTime thumbTime = CMTimeMakeWithSeconds(0, 60);
    generator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    AVAssetImageGeneratorCompletionHandler generatorHandler =
    ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *thumbImg = [UIImage imageWithCGImage:im];
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(asset,thumbImg);
                });
            }
        } else {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(nil,nil);
                });
            }
        }
    };
    [generator generateCGImagesAsynchronouslyForTimes:
     [NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:generatorHandler];
}

#pragma mark - 切换前后摄像头
- (void)cameraPosition:(NSString *)camera {
    if ([camera isEqualToString:@"前置"]) {
        if (self.videoDevice.position != AVCaptureDevicePositionFront) {
            self.position = AVCaptureDevicePositionFront;
        }
    }
    else if ([camera isEqualToString:@"后置"]){
        if (self.videoDevice.position != AVCaptureDevicePositionBack) {
            self.position = AVCaptureDevicePositionBack;
        }
    }
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:self.position];
    if (device) {
        self.videoDevice = device;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
        [self.recordSession beginConfiguration];
        [self.recordSession removeInput:self.videoInput];
        if ([self.recordSession canAddInput:input]) {
            [self.recordSession addInput:input];
            self.videoInput = input;
            [self.recordSession commitConfiguration];
        }
    }
}


/**
 获取视频存放地址
 */
- (NSString *)getVideoCachePath {
    NSString *videoCache = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videos"] ;
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}

- (NSString *)getUploadFileType:(NSString *)type fileType:(NSString *)fileType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate *NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    
    NSString *timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.%@", type, timeStr, fileType];
    return fileName;
}

#pragma mark - 写入数据 AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (!self.isCapturing) {
        return;
    }
    
    
    BOOL isVideo = YES;
    
    
    
    //限制在一个线程执行
    @synchronized(self) {
        if (!self.isCapturing) {
            return;
        }
        if (captureOutput != self.videoOutput) {
            isVideo = NO;
        }
        
        //初始化编码器，当有音频和视频参数时创建编码器
        if ((self.recordEncoder == nil) && !isVideo) {
            CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer); //格式信息 CMFormatDescription
            const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
            int channels = asbd -> mChannelsPerFrame;//声道
            Float64 samplerate = asbd -> mSampleRate;//音频采样率
            
            if (channels == 0) channels = 2;
            if (samplerate == 0) samplerate = 44100;
            
            NSString *videoName = [self getUploadFileType:@"video" fileType:@"mp4"];
            self.videoPath = [[self getVideoCachePath] stringByAppendingPathComponent:videoName];
            /// 这里只是数据写入的大小 不是改变原来视频的大小
            self.recordEncoder = [HDUploadRecordEncoder encoderForPath:self.videoPath
                                                                height:640
                                                                 width:480
                                                              channels:channels
                                                               samples:samplerate];
        }
        
        
    }
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = dur;
    }
    CMTime sub = CMTimeSubtract(dur, self.startTime);
    self.currentRecordTime = CMTimeGetSeconds(sub); //获取秒数
    if (self.currentRecordTime > self.maxRecordTime) {
        if (self.currentRecordTime - self.maxRecordTime < 0.1) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewProgress:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate uploadIntroRecordViewProgress:self.currentRecordTime / self.maxRecordTime];
                });
                
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopCapture];
            self.isCapturing = NO;
            NSLog(@"dispatch_get_main_queue 2 ");
        });
        
        NSLog(@"dispatch_get_main_queue 1 ");

        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate uploadIntroRecordViewProgress:self.currentRecordTime / self.maxRecordTime];
        });
    }
    
    
    // 进行数据编码  1280x720
    if (isVideo) {        
        [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
    } else {
        [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
    }
}


#pragma mark - setter & getter
/// 捕获到的视频呈现的layer
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        //通过AVCaptureSession初始化
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
        //设置比例为铺满全屏
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

/// 捕获视频的会话
- (AVCaptureSession *)recordSession {
    //作为协调输入与输出的中心,第一步需要创建一个Session
    if (!_recordSession) {
        _recordSession = [[AVCaptureSession alloc] init];
        
        _recordSession.sessionPreset = AVCaptureSessionPreset640x480;

        
        //使用AVCaptureDeviceInput来让设备添加到session中, AVCaptureDeviceInput负责管理设备端口
        //添加后置摄像头的输入 （前置摄像头切换时添加）
        if ([_recordSession canAddInput:self.videoInput]) {
            [_recordSession addInput:self.videoInput];
        }
        //添加麦克风的输入
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        
        //添加AVCaptureOutput以从session中取得数据
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _recordSession;
}

/// 创建输入设备 设置默认前置摄像头
- (AVCaptureDevice *)videoDevice {
    if (!_videoDevice) {
        _videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    }
    return _videoDevice;
}
/// 视频输入
- (AVCaptureDeviceInput *)videoInput {
    if (_videoInput == nil) {
        NSError *error;
        _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewFailWithReason:)]) {
                [self.delegate uploadIntroRecordViewFailWithReason:@"获取摄像头失败~"];
            }
        }
    }
    return _videoInput;
}
/// 视频连接
- (AVCaptureConnection *)videoConnection {
    if (!_videoConnection) {
        _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}
/// 视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t audioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        
        [_videoOutput setSampleBufferDelegate:self queue:audioQueue];
        /**
         除了设置代理以外，还需要设置一个serial queue来供代理调用，这里必须使用serial queue来保证传给delegate的帧数据的顺序正确。我们可以使用这个 queue 来分发和处理视频帧
         */
        NSDictionary *setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
        
        /** default YES 来确保晚到的帧会被丢掉来避免延迟。
         如果不介意延迟，而更想要处理更多的帧，那就设置这个值为 NO，但是这并不意味着不会丢帧，只是不会被那么早或那么高效的丢掉。
         */
        _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    }
    return _videoOutput;
}


/// 麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (!_audioMicInput) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewFailWithReason:)]) {
                [self.delegate uploadIntroRecordViewFailWithReason:@"获取麦克风失败~"];
            }
        }
    }
    return _audioMicInput;
}
/// 音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (!_audioOutput) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        dispatch_queue_t audioQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        [_audioOutput setSampleBufferDelegate:self queue:audioQueue];
    }
    return _audioOutput;
}
/// 音频连接
- (AVCaptureConnection *)audioConnection {
    if (!_audioConnection) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}
@end
