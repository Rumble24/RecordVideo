//
//  HDImagePicker.m
//  视频录制
//
//  Created by 王景伟 on 2020/9/21.
//  Copyright © 2020 王景伟. All rights reserved.
//

#import "HDImagePicker.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AVCaptureMovieFileOutputController.h"
#import "AVAssetWriterController.h"
#import <AVFoundation/AVFoundation.h>

@interface HDImagePicker ()
<
UITableViewDelegate,
UITableViewDataSource,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate
>

@property (nonatomic, strong) NSArray *dataArr;

@end

@implementation HDImagePicker

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    /// 1.UIImagePickerController
    /// 2.AVCaptureSession + AVCaptureMovieFileOutput
    /// 3.AVCaptureSession + AVAssetWriter

    self.dataArr = @[@"UIImagePickerController",@"AVCaptureSession + AVCaptureMovieFileOutput",@"AVCaptureSession + AVAssetWriter"];
    
    UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"UITableViewCell"];
    [self.view addSubview:tableView];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.dataArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//     AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);//默认震动效果

    // 普通短震，3D Touch 中 Pop 震动反馈
//    AudioServicesPlaySystemSound(1520);
    
    // 普通短震，3D Touch 中 Peek 震动反馈
//    AudioServicesPlaySystemSound(1519);


    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleLight];
    [generator prepare];
    [generator impactOccurred];
    
    switch (indexPath.row) {
        case 0:
            [self selectImageSource];
            break;
        case 1:
            [self presentViewController:AVCaptureMovieFileOutputController.new animated:YES completion:nil];
            break;
        case 2:
            [self presentViewController:AVAssetWriterController.new animated:YES completion:nil];
            break;
        default:
            break;
    }
}

- (void)selectImageSource {
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"从相机拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            //设置照片来源
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = YES;//编辑模式  但是编辑框是正方形的
            // 使用前置还是后置摄像头
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            
            // 设置可用的媒体类型、默认只包含kUTTypeImage
            imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
    }];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES;//编辑模式  但是编辑框是正方形的
        // 使用前置还是后置摄像头
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        
        // 设置可用的媒体类型、默认只包含kUTTypeImage
        imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        [self presentViewController:imagePicker animated:YES completion:nil];
    }];
    // imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage];

    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"点击了取消");
    }];
    
    [actionSheet addAction:cameraAction];
    [actionSheet addAction:photoAction];
    [actionSheet addAction:cancelAction];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
    
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    [self calulateImageFileSize:image];
    //当选择的类型是图片
    if ([type isEqualToString:@"public.image"]) {
    }
}


- (void)calulateImageFileSize:(UIImage *)image {
    
    NSData *data = UIImagePNGRepresentation(image);
    if (!data) {
        data = UIImageJPEGRepresentation(image, 0.5);//需要改成0.5才接近原图片大小，原因请看下文
    }
    double dataLength = [data length] * 1.0;
    NSArray *typeArray = @[@"bytes",@"KB",@"MB",@"GB",@"TB",@"PB", @"EB",@"ZB",@"YB"];
    NSInteger index = 0;
    while (dataLength > 1024) {
        dataLength /= 1024.0;
        index ++;
    }
    NSLog(@"image = %.3f %@",dataLength,typeArray[index]);
}

@end
