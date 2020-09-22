//
//  MovieFileOutputView.h
//  视频录制
//
//  Created by 王景伟 on 2020/9/21.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MovieFileOutputViewDelegate <NSObject>
@optional
/// 开始录制
- (void)uploadIntroRecordViewDidStartRecording;
/// 录制完成回调
- (void)uploadIntroRecordViewDidFinishRecordingToOutputFile:(NSURL *)url imageCover:(UIImage *)imageCover;
@end

@interface MovieFileOutputView : UIView

@property (nonatomic, weak) id<MovieFileOutputViewDelegate> delegate;

// 闪光灯开关
- (void)lightAction;
//停止运行
- (void)stopRunning;
//开始运行
- (void)startRunning;
//开始录制
- (void) startCapture;
//停止录制
- (void) stopCapture;
// 切换前后摄像头 camera 前置、后置
- (void)cameraPosition:(NSString *)camera;

// 保存到相册
- (void)saveToPhotoLibraryCompletionHandler:(nullable void(^)(BOOL success, NSError *__nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
