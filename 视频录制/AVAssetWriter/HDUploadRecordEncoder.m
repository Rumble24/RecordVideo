//
//  HDUploadRecordEncoder.m
//  SJRecordVideoDemo
//
//  Created by Soldier on 2017/6/19.
//  Copyright © 2017年 Shaojie Hong. All rights reserved.
//

#import "HDUploadRecordEncoder.h"

@interface HDUploadRecordEncoder ()
///<    媒体写入对象
@property (nonatomic, strong) AVAssetWriter *writer;
///<    视频写入
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
///<    音频写入
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
///<    写入路径
@property (nonatomic, strong) NSString *path;

@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@end




@implementation HDUploadRecordEncoder

- (void)dealloc {
    _writer = nil;
    _videoInput = nil;
    _audioInput = nil;
    _path = nil;
}

/**
 HDUploadRecordEncoder遍历构造器的
 */
+ (HDUploadRecordEncoder *)encoderForPath:(NSString *)path
                             height:(NSInteger)height
                              width:(NSInteger)width
                           channels:(int)ch
                            samples:(Float64)rate {
    HDUploadRecordEncoder *recordEncoder = [[HDUploadRecordEncoder alloc] initPath:path height:height width:width channels:ch samples:rate];
    return recordEncoder;
}

/**
 初始化方法
 */
- (instancetype)initPath:(NSString *)path
                  height:(NSInteger)height
                   width:(NSInteger)width
                channels:(int)ch
                 samples:(Float64)rate {
    self = [super init];
    if (self) {
        self.path = path;
        //先把路径下的文件给删除掉,保证录制的文件是最新的
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        NSURL *url = [NSURL fileURLWithPath:self.path];
        
        //初始化写入媒体类型为MP4类型
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        //使其更适合在网络上播放
        _writer.shouldOptimizeForNetworkUse = YES;
        //初始化视频输出
        [self initVideoInputHeight:height width:width];
        //确保采集到rate和ch
        if (rate != 0 && ch != 0) {
            //初始化音频输出
            [self initAudioInputChannels:ch samples:rate];
        }
    }
    return self;
}

/**
 初始化视频输入
 */
- (void)initVideoInputHeight:(NSInteger)height width:(NSInteger)width {
    //写入视频大小
    NSInteger numPixels = height * width;
    //每像素比特
    CGFloat bitsPerPixel = 6.0;
    NSInteger bitsPerSecond = numPixels * bitsPerPixel;
    
    // 码率和帧率设置
    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30),
                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
    
    //视频属性
    self.videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecTypeH264,
                                       AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                       AVVideoWidthKey : @(height),
                                       AVVideoHeightKey : @(width),
                                       AVVideoCompressionPropertiesKey : compressionProperties };
    //初始化视频写入类
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
    //实时采集数据源
    _videoInput.expectsMediaDataInRealTime = YES;
    //将视频输入源加入
    if ([_writer canAddInput:_videoInput]) {
        [_writer addInput:_videoInput];
    }
}

/**
 初始化音频输入
 */
- (void)initAudioInputChannels:(int)ch samples:(Float64)rate {
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率 128 kbps
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [NSNumber numberWithInt:ch], AVNumberOfChannelsKey,
                              [NSNumber numberWithFloat:rate], AVSampleRateKey,
                              [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
                              nil];
    //初始化音频写入类
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //实时采集数据源
    _audioInput.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    if ([_writer canAddInput:_audioInput]) {
        [_writer addInput:_audioInput];
    }
}

/**
 完成视频录制时调用
 */
- (void)finishWithCompletionHandler:(void (^)(void))handler {
    [_writer finishWritingWithCompletionHandler:handler];
}

/**
 通过这个方法写入数据
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo {
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态为未知,保证视频先写入
        if (_writer.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (_writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        //判断是否是视频
        if (isVideo) {
            //视频输入是否准备接受更多的媒体数据
            if (_videoInput.readyForMoreMediaData) {
                //拼接数据
                [_videoInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        } else {
            //音频输入是否准备接受更多的媒体数据
            if (_audioInput.readyForMoreMediaData) {
                //拼接数据
                [_audioInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }
    }
    return NO;
}

@end
