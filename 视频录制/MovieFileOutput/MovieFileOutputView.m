//
//  MovieFileOutputView.m
//  视频录制
//
//  Created by 王景伟 on 2020/9/21.
//  Copyright © 2020 王景伟. All rights reserved.
//  http://www.cocoachina.com/articles/16328
/// https://www.juejin.im/post/6844904121619726343#heading-14

#import "MovieFileOutputView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface MovieFileOutputView ()<AVCaptureFileOutputRecordingDelegate>
@property (nonatomic, strong) AVCaptureSession * captureSession;  //负责输入和输出设备之间的连接会话
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput; // 输入源
@property (nonatomic, strong) AVCaptureVideoPreviewLayer * previewLayer;//捕获到的视频呈现的layer
@property (nonatomic, strong) AVCaptureDeviceInput * audioMicInput;//麦克风输入
@property (nonatomic, strong) AVCaptureConnection * videoConnection;//视频录制连接
@property (nonatomic, strong) AVCaptureMovieFileOutput * captureMovieFileOutput;//视频输出流
@property (nonatomic, strong) AVCaptureDevice *captureDevice;   // 输入设备
@property (nonatomic, assign) AVCaptureDevicePosition position;//设置焦点
@property (nonatomic, assign) AVCaptureFlashMode mode;//设置聚焦曝光
@property (nonatomic, strong) NSURL *videoURL;//视频路径
@end

@implementation MovieFileOutputView

- (void)dealloc {
    [self.captureSession stopRunning];
    NSLog(@"%s",__func__);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.layer insertSublayer:self.previewLayer atIndex:0];
        __weak typeof(self)weakSelf = self;
        //    监听屏幕方向
        [[NSNotificationCenter   defaultCenter]addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            weakSelf.previewLayer.connection.videoOrientation = [self getCaptureVideoOrientation];
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.bounds;
    [self startRunning];
}


#pragma mark - 开始运行
- (void)startRunning {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.captureSession startRunning];
    });
}


#pragma mark - 停止运行
- (void)stopRunning {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.captureSession stopRunning];
    });
}


#pragma mark - 获取视频方向
- (AVCaptureVideoOrientation)getCaptureVideoOrientation {
    AVCaptureVideoOrientation result;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            result = AVCaptureVideoOrientationPortrait;
            break;
    }
    return result;
}

//开始录制
- (void)startCapture {
    if (self.captureMovieFileOutput.isRecording) {
        return;
    }
    NSString *defultPath = [self getVideoPathCache];
    NSString *outputFielPath = [defultPath stringByAppendingPathComponent:[self getVideoNameWithType:@"mp4"]];
    NSURL *fileUrl = [NSURL fileURLWithPath:outputFielPath];
    //设置录制视频流输出的路径
    [self.captureMovieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
}

//停止录制
- (void) stopCapture {
    if ([self.captureMovieFileOutput isRecording]) {
        [self.captureMovieFileOutput stopRecording];//停止录制
    }
}

#pragma mark - 闪光灯开关
- (void)lightAction {
    if (self.mode == AVCaptureFlashModeOn) {
        [self setMode:AVCaptureFlashModeOff];
    } else {
        [self setMode:AVCaptureFlashModeOn];
    }
}


#pragma mark - 切换前后摄像头
- (void)cameraPosition:(NSString *)camera{
    if ([camera isEqualToString:@"前置"]) {
        if (self.captureDevice.position != AVCaptureDevicePositionFront) {
            self.position = AVCaptureDevicePositionFront;
        }
    }
    else if ([camera isEqualToString:@"后置"]){
        if (self.captureDevice.position != AVCaptureDevicePositionBack) {
            self.position = AVCaptureDevicePositionBack;
        }
    }
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:self.position];
    if (device) {
        self.captureDevice = device;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
        [self.captureSession beginConfiguration];
        [self.captureSession removeInput:self.captureDeviceInput];
        if ([self.captureSession canAddInput:input]) {
            [self.captureSession addInput:input];
            self.captureDeviceInput = input;
            [self.captureSession commitConfiguration];
        }
    }
}

#pragma mark - 视频输出代理开始录制
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewDidStartRecording)]) {
        [self.delegate uploadIntroRecordViewDidStartRecording];
    }
    NSLog(@" 开始录制 ");
}

#pragma mark - 录制完成回调
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [self adjustTheSizeWithPath:outputFileURL];
}

- (void)adjustTheSizeWithPath:(NSURL *)path {
    NSError *error = nil;
    CGSize renderSize = CGSizeMake(0, 0);
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc] init];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    CMTime totalDuration = kCMTimeZero;
    
    AVAsset *asset = [AVAsset assetWithURL:path];
    if (!asset) return;
    
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    if (!assetTrack) return;
    
    renderSize.width = MAX(renderSize.width, assetTrack.naturalSize.width);
    renderSize.height = MAX(renderSize.height, assetTrack.naturalSize.height);
    if (renderSize.height == 0 || renderSize.width == 0) return;
    
    NSLog(@"renderSize  %f  %f",renderSize.width,renderSize.height);
    
    CGFloat renderW = MIN(renderSize.width, renderSize.height);
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetAudioTrack atTime:totalDuration error:nil];
    } else {
        NSLog(@"Reminder: video hasn't audio!");
    }

    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];

    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetTrack atTime:totalDuration error:&error];
    
    // Fix orientation issue
    AVMutableVideoCompositionLayerInstruction *layerInstruciton = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    totalDuration = CMTimeAdd(totalDuration, asset.duration);

    CGFloat rate = renderW / MIN(assetTrack.naturalSize.width, assetTrack.naturalSize.height);

    CGAffineTransform layerTransform = CGAffineTransformMake(assetTrack.preferredTransform.a, assetTrack.preferredTransform.b, assetTrack.preferredTransform.c, assetTrack.preferredTransform.d, assetTrack.preferredTransform.tx * rate, assetTrack.preferredTransform.ty * rate);
    layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(assetTrack.naturalSize.width - assetTrack.naturalSize.height) / 2.0));
    //rate
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);

    [layerInstruciton setTransform:layerTransform atTime:kCMTimeZero];
    [layerInstruciton setOpacity:0.0 atTime:totalDuration];

    [layerInstructionArray addObject:layerInstruciton];
    

    NSString *savePath = NSTemporaryDirectory();
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    
    NSString *fileName = [[savePath stringByAppendingPathComponent:nowTimeStr] stringByAppendingString:@"mov.mov"];
    self.videoURL = [NSURL fileURLWithPath:fileName];
    NSLog(@"%@",fileName);

    
    AVMutableVideoCompositionInstruction *mainInstruciton = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruciton.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    mainInstruciton.layerInstructions = layerInstructionArray;

    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    mainCompositionInst.instructions = @[mainInstruciton];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.renderSize = CGSizeMake(renderW, renderW * CGRectGetHeight(self.bounds) / CGRectGetWidth(self.bounds));
    

    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.videoComposition = mainCompositionInst;
    exporter.outputURL = self.videoURL;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.outputFileType = AVFileTypeMPEG4;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([exporter status] == AVAssetExportSessionStatusCompleted) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploadIntroRecordViewDidFinishRecordingToOutputFile:imageCover:)]) {
                    UIImage *imageCover = [self firstFrameWithVideoURL:self.videoURL];
                    [self.delegate uploadIntroRecordViewDidFinishRecordingToOutputFile:self.videoURL imageCover:imageCover];
                }
            }
        });
    }];
}

/**
 获取视频第一帧的图片
 */
- (UIImage *)firstFrameWithVideoURL:(NSURL *)url {
    // 获取视频第一帧
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 10) actualTime:NULL error:&error]; {
        return [UIImage imageWithCGImage:img];
    }
    return nil;
}



- (void)saveToPhotoLibraryCompletionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:self.videoURL];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(success,error);
            }
        }];
    });
}


#pragma mark - 视频地址
- (NSString *)getVideoPathCache {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * videoCache = [[paths firstObject] stringByAppendingPathComponent:@"videos"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:videoCache isDirectory:&isDir];
    if ( !(isDir == YES && existed == YES) ) {
        [fileManager createDirectoryAtPath:videoCache withIntermediateDirectories:YES attributes:nil error:nil];
    };
    return videoCache;
}



#pragma mark - 拼接视频文件名称
- (NSString *)getVideoNameWithType:(NSString *)fileType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"video_%@.%@",timeStr,fileType];
    return fileName;
}


#pragma mark - 设置相机画布
- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}


#pragma mark - 创建会话
- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720; // 画质
        // 5. 连接输入与会话
        if ([_captureSession canAddInput:self.captureDeviceInput]) {
            [_captureSession addInput:self.captureDeviceInput];
        }
        
        // 添加麦克风设备
        if ([_captureSession canAddInput:self.audioMicInput]) {
            [_captureSession addInput:self.audioMicInput];
        }
        
        // 6. 连接输出与会话
        if ([_captureSession canAddOutput:self.captureMovieFileOutput]) {
            [_captureSession addOutput:self.captureMovieFileOutput];
        }
    }
    return _captureSession;
}

/// 创建输入设备
- (AVCaptureDevice *)captureDevice {
    if (!_captureDevice) {
        //        设置默认前置摄像头
        _captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    }
    return _captureDevice;
}

/// 视频创建输入源
- (AVCaptureDeviceInput *)captureDeviceInput {
    if (!_captureDeviceInput) {
        _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
    }
    return _captureDeviceInput;
}

/// 麦克风输入源
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            //  NSLog(@"获取麦克风失败~%d",[self isAvailableWithMic]);
        }
    }
    return _audioMicInput;
}

///  输出视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([_videoConnection isVideoStabilizationSupported]) {
        _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        _videoConnection.videoScaleAndCropFactor = 1;
        
        
        
    }
    return _videoConnection;
}




/// 初始化设备输出对象，用于获得输出数据
- (AVCaptureMovieFileOutput *)captureMovieFileOutput {
    if(_captureMovieFileOutput == nil) {
        _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    }
    return _captureMovieFileOutput;
}


#pragma mark - 获取焦点
- (AVCaptureDevicePosition)position {
    if (!_position) {
        _position = AVCaptureDevicePositionFront;
    }
    return _position;
}

@end
