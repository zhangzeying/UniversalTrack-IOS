//
//  TrackViewController.m
//  ChildTrack
//
//  Created by zzy on 14/01/2018.
//  Copyright © 2018 zzy. All rights reserved.
//

#import "TrackViewController.h"
#import "SGQRCode.h"
#import "MapViewController.h"
#import "TrackManage.h"
#import "SGQRCodeScanningVC.h"

@interface TrackViewController ()<SGQRCodeScanManagerDelegate, SGQRCodeAlbumManagerDelegate>

@property (nonatomic, strong) SGQRCodeScanManager *scanManager;
@property (nonatomic, weak) UITextField *contentTxt;

@end

@implementation TrackViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"追踪他人";
    
    UIButton *scanQrCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    scanQrCodeBtn.backgroundColor = [UIColor colorWithHexString:@"de88a5"];
    [scanQrCodeBtn setTitle:@"扫描要追踪的二维码" forState:UIControlStateNormal];
    scanQrCodeBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    scanQrCodeBtn.layer.cornerRadius = 10;
    scanQrCodeBtn.frame = CGRectMake(15, 95, ScreenW - 2*15, 50);
    [scanQrCodeBtn addTarget:self action:@selector(scanQrCodeClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanQrCodeBtn];

    UIButton *trackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    trackBtn.backgroundColor = [UIColor colorWithHexString:@"de88a5"];
    [trackBtn setTitle:@"开始追踪" forState:UIControlStateNormal];
    trackBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    trackBtn.layer.cornerRadius = 6;
    trackBtn.frame = CGRectMake(ScreenW-15-80, scanQrCodeBtn.bottom+30, 80, 35);
    [trackBtn addTarget:self action:@selector(trackBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:trackBtn];
    
    UITextField *contentTxt = [[UITextField alloc]init];
    contentTxt.frame = CGRectMake(scanQrCodeBtn.x, scanQrCodeBtn.bottom+33, trackBtn.x - 25 - scanQrCodeBtn.x, 30);
    contentTxt.placeholder = @"请输入要追踪的ID";
    contentTxt.borderStyle = UITextBorderStyleNone;
    contentTxt.font = [UIFont systemFontOfSize:14];
    contentTxt.textColor = [UIColor grayColor];
    contentTxt.tintColor = [UIColor colorWithHexString:@"ff4081"];
    contentTxt.clearButtonMode = UITextFieldViewModeAlways;
    [self.view addSubview:contentTxt];
    self.contentTxt = contentTxt;
    
    UIView *line = [[UIView alloc]init];
    line.frame = CGRectMake(contentTxt.x, contentTxt.bottom, contentTxt.width, 1);
    line.backgroundColor = [UIColor colorWithHexString:@"ff4081"];
    [self.view addSubview:line];
    
}

- (void)scanQrCodeClick {
    
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        SGQRCodeScanningVC *vc = [[SGQRCodeScanningVC alloc] init];
                        [self.navigationController pushViewController:vc animated:YES];
                    });
                    // 用户第一次同意了访问相机权限
                    DLog(@"用户第一次同意了访问相机权限 - - %@", [NSThread currentThread]);
                    
                } else {
                    // 用户第一次拒绝了访问相机权限
                    DLog(@"用户第一次拒绝了访问相机权限 - - %@", [NSThread currentThread]);
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            SGQRCodeScanningVC *vc = [[SGQRCodeScanningVC alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"请去-> [设置 - 隐私 - 相机 - SGQRCodeExample] 打开访问开关" preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            DLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"未检测到您的摄像头" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

/**
 * 开始追踪
 */
- (void)trackBtnClick {
    
    [SVProgressHUD show];
    __weak typeof (self)wSelf = self;
    [[TrackManage sharedInstance] trackWithCompletionBlock:self.contentTxt.text trackBlock:^(BMKMapPoint *points, NSMutableArray *poisWithoutZero) {
       
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [SVProgressHUD dismiss];
            MapViewController *map = [[MapViewController alloc]initWithParams:poisWithoutZero points:points];
            [wSelf.navigationController pushViewController:map animated:YES];
        });
        
    }];
}



#pragma mark - - - SGQRCodeAlbumManagerDelegate
//- (void)QRCodeAlbumManagerDidCancelWithImagePickerController:(SGQRCodeAlbumManager *)albumManager {
//    [self.view addSubview:self.scanningView];
//}
//- (void)QRCodeAlbumManager:(SGQRCodeAlbumManager *)albumManager didFinishPickingMediaWithResult:(NSString *)result {
//    if ([result hasPrefix:@"http"]) {
//        ScanSuccessJumpVC *jumpVC = [[ScanSuccessJumpVC alloc] init];
//        jumpVC.jump_URL = result;
//        [self.navigationController pushViewController:jumpVC animated:YES];
//
//    } else {
//        ScanSuccessJumpVC *jumpVC = [[ScanSuccessJumpVC alloc] init];
//        jumpVC.jump_bar_code = result;
//        [self.navigationController pushViewController:jumpVC animated:YES];
//    }
//}

#pragma mark - - - SGQRCodeScanManagerDelegate
- (void)QRCodeScanManager:(SGQRCodeScanManager *)scanManager didOutputMetadataObjects:(NSArray *)metadataObjects {
    DLog(@"metadataObjects - - %@", metadataObjects);
    if (metadataObjects != nil && metadataObjects.count > 0) {

        [scanManager palySoundName:@"SGQRCode.bundle/sound.caf"];
        [scanManager stopRunning];
        [scanManager videoPreviewLayerRemoveFromSuperlayer];
        
        AVMetadataMachineReadableCodeObject *obj = metadataObjects[0];
//        ScanSuccessJumpVC *jumpVC = [[ScanSuccessJumpVC alloc] init];
//        jumpVC.jump_URL = [obj stringValue];
//        [self.navigationController pushViewController:jumpVC animated:YES];
        
    } else {
        DLog(@"暂未识别出扫描的二维码");
    }
}

- (void)QRCodeScanManager:(SGQRCodeScanManager *)scanManager brightnessValue:(CGFloat)brightnessValue {
//    if (brightnessValue < - 1) {
//        [self.view addSubview:self.flashlightBtn];
//    } else {
//        if (self.isSelectedFlashlightBtn == NO) {
//            [self removeFlashlightBtn];
//        }
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
   
}

@end
