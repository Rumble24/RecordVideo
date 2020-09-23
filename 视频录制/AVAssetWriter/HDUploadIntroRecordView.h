//
//  HDUploadIntroRecordView.h
//  yanxishe
//
//  Created by 王景伟 on 2020/9/9.
//  Copyright © 2020 hundun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/**
 * CameraRecord 录制视频比例类型定义  高 宽比
 */
typedef NS_ENUM(NSInteger, HDVideoAspectRatio) {
    /// 3:4
    HD_VIDEO_RATIO_3_4,
    /// 9:16
    HD_VIDEO_RATIO_9_16,
    /// 1:1
    HD_VIDEO_RATIO_1_1,
    /// 16:9
    HD_VIDEO_RATIO_16_9,
    /// 4:3
    HD_VIDEO_RATIO_4_3,
    /// 全屏
    HD_VIDEO_RATIO_FULL,
};

NS_ASSUME_NONNULL_BEGIN

@protocol HDUploadIntroRecordViewDelegate <NSObject>
@optional
/// 开始录制
- (void)uploadIntroRecordViewDidStartRecording;
/// 录制的进度百分比
- (void)uploadIntroRecordViewProgress:(CGFloat)progress;
/// 录制失败
- (void)uploadIntroRecordViewFailWithReason:(NSString *)reason;
/// 录制完成回调
- (void)uploadIntroRecordViewDidFinishRecordingToAsset:(AVURLAsset *)asset imageCover:(UIImage *)imageCover;
@end

@interface HDUploadIntroRecordView : UIView

@property (nonatomic,   weak) id<HDUploadIntroRecordViewDelegate> delegate;
/// 最长录制时间  startRunning 前调用
@property (nonatomic, assign) CGFloat maxRecordTime;
/// 分辨率 startRunning 前调用
@property (nonatomic,   copy) AVCaptureSessionPreset sessionPreset;


/// 设置录制的宽高 startRunning 前调用
- (void)setAspectRatio:(HDVideoAspectRatio)videoRatio;

/// 开始运行
- (void)startRunning;
/// 停止运行
- (void)stopRunning;
/// 开始录制
- (void)startCapture;
/// 停止录制
- (void)stopCapture;
///  切换前后摄像头 前置、后置
- (void)cameraPosition:(NSString *)camera;

// 保存到相册
- (void)saveToPhotoLibraryCompletionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler;
@end

NS_ASSUME_NONNULL_END
