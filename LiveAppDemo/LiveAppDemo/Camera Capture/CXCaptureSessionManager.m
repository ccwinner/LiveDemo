//
//  CXCaptureSessionManager.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/18.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#import "CXCaptureSessionManager.h"
#import "CXCameraInput.h"
#import "CXCameraOutput.h"

@interface CXCaptureSessionManager ()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) CXCameraInput *input;
@property (nonatomic, strong) CXCameraOutput *output;

@property (nonatomic, strong) AVCaptureConnection *connection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoLayer;

@property (nonatomic, assign) NSInteger frameRate; //default is 30
@end

@implementation CXCaptureSessionManager

+ (instancetype)manager {
    CXCaptureSessionManager *manager = [CXCaptureSessionManager new];
    manager.frameRate = 30;
    return manager;
}

- (void)setupSession {
    self.session = [AVCaptureSession new];

    [self configInput];
    [self configOutput];

    if ([self.session canAddInput:self.input.capturedDeviceInput]) {
        [self.session addInput:self.input.capturedDeviceInput];
    }
    if ([self.session canAddOutput:self.output.capturedDeviceOutput]) {
        [self.session addOutput:self.output.capturedDeviceOutput];
    }

    //720p
    [self changeResolution:CXCaptureResolutionType720p];

    [self configConnection];

//    [self configPreviewLayer];
    //配置输出帧率
    [self changeFrameRate:self.frameRate];
}

- (void)flipCameraToFront:(BOOL)captureFront {
    AVCaptureDeviceInput *oldInput = self.input.capturedDeviceInput;
    //创建新的input
    [self.input useCameraPosition:captureFront ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack];
    AVCaptureDeviceInput *newInput = self.input.capturedDeviceInput;
    //session 移出老的input 提交改动
    [self.session beginConfiguration];
    [self.session removeInput:oldInput];

    if ([self.session canAddInput:newInput]) {
        [self.session addInput:newInput];
    } else {
        NSLog(@"翻转摄像头失败");
    }
    [self.session commitConfiguration];

    // 重新获取连接并设置方向
    [self configConnection];
}

- (void)changeResolution:(CXCaptureResolutionType)type {
    AVCaptureSessionPreset preset = nil;
    switch (type) {
        case CXCaptureResolutionTypeLow:
            preset = AVCaptureSessionPresetLow;
            break;
        case CXCaptureResolutionTypeMedium:
            preset = AVCaptureSessionPresetMedium;
            break;
        case CXCaptureResolutionTypeHigh:
            preset = AVCaptureSessionPresetHigh;
            break;
        case CXCaptureResolutionType720p:
            preset = AVCaptureSessionPreset1280x720;
            break;
        case CXCaptureResolutionType1080p:
            preset = AVCaptureSessionPreset1920x1080;
            break;
        default:
            preset = AVCaptureSessionPreset1920x1080;
            break;
    }
    if ([self.session canSetSessionPreset:preset]) {
        self.session.sessionPreset = preset;
    }
}

- (void)changeFrameRate:(NSInteger)frameRate {
    if (self.frameRate == frameRate) {
        return;
    }
    self.frameRate = frameRate;

    AVFrameRateRange *frameRateRange = self.input.camera.activeFormat.videoSupportedFrameRateRanges.firstObject;
    if (self.frameRate > frameRateRange.maxFrameRate || self.frameRate < frameRateRange.minFrameRate) {
        NSLog(@"frameRate不支持");
        return;
    }

    NSError *error = nil;
    [self.input.camera lockForConfiguration:&error];
    if (error) {
        NSLog(@"camera lock configuration失败");
        return;
    }
    self.input.camera.activeVideoMinFrameDuration = CMTimeMake(1, (int)self.frameRate);
    [self.input.camera unlockForConfiguration];
}

+ (void)requestCameraPermission:(void(^)(BOOL granted))callback {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:callback];
}

- (void)startCapture {
    //todo:开始采集视频
    __weak typeof(self) weakS = self;
    void (^handler)(BOOL) = ^(BOOL granted) {
        if (granted) {
            [weakS.session startRunning];
        }
    };
    if (AVAuthorizationStatusAuthorized != [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {

        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:handler];
    } else {
        handler(YES);
    }
}

- (void)stopCapture {
    [self.session stopRunning];
}

#pragma mark - Logic
- (void)configInput {
    self.input = [[CXCameraInput alloc] initWithSession:self.session];
    [self.input prepareForInput];
}

- (void)configOutput {
    self.output = [[CXCameraOutput alloc] initWithSession:self.session];
    [self.output useVideoOutputOfYUV];
    __weak typeof(self) weakS = self;
    self.output.didOutputData = ^(CMSampleBufferRef  _Nonnull sampleBuffer, AVCaptureConnection * _Nonnull connection) {
        //用来将数据进行处理 美颜等效果用的
        [weakS.delegate outputSamplebuffer:sampleBuffer];
    };
}

- (void)configConnection {
    //output的connection和preViewLayer的connection
    //不是同一个实例，两个要分别设置横竖屏等配置,才能保证output导出的数据流配置与preview的一致

    //如果不这样设置 (GPUImage就没有设置）
    //则在convertYUVtoRGBoutput阶段, gpuimage做了两次shader的link和运行，第一次的纹理坐标传入右转矩阵,第二次传入的才是显示用的上下翻转矩阵。
    //如果这里设置了,则只需上下翻转矩阵就行。
    self.connection = ({
        __auto_type conn = [self.output.capturedDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
        //采集到的是竖屏流
        conn.videoOrientation = AVCaptureVideoOrientationPortrait;
        if (self.input.camera.position == AVCaptureDevicePositionFront && conn.supportsVideoMirroring) {
            conn.videoMirrored = YES;
        }
        conn;
    });
}

- (void)configPreviewLayer {
    self.videoLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.videoLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

@end
