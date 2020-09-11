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
- (void)uploadIntroRecordViewDidFinishRecordingToOutputFile:(AVURLAsset *)asset imageCover:(UIImage *)imageCover;
@end

@interface HDUploadIntroRecordView : UIView

@property (nonatomic, weak) id<HDUploadIntroRecordViewDelegate> delegate;
/// 最长录制时间
@property (nonatomic, assign) CGFloat maxRecordTime;

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
@end

NS_ASSUME_NONNULL_END
