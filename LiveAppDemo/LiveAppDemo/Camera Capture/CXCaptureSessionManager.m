//
//  CXCaptureSessionManager.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CXCaptureSessionManager.h"
#import "CXCameraInput.h"
#import "CXCameraOutput.h"

@interface CXCaptureSessionManager ()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) CXCameraInput *input;
@property (nonatomic, strong) CXCameraOutput *output;
@property (nonatomic, copy) AVCaptureConnection *connection;
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

- (void)startCapture {
    //todo:开始采集视频
}

#pragma mark - Logic
- (void)configInput {
    self.input = [[CXCameraInput alloc] initWithSession:self.session];
    [self.input prepareForInput];
}

- (void)configOutput {
    self.output = [[CXCameraOutput alloc] initWithSession:self.session];
    [self.output useVideoOutputOfYUV];
}

- (void)configConnection {
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

@end
