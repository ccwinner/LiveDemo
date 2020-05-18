//
//  CXCaptureSessionManager.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CXCaptureSessionManager.h"
#import <AVFoundation/AVFoundation.h>
#import "CXCameraInput.h"
#import "CXCameraOutput.h"

@interface CXCaptureSessionManager ()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) CXCameraInput *input;
@property (nonatomic, strong) CXCameraOutput *output;
@property (nonatomic, copy) AVCaptureConnection *connection;
@end

@implementation CXCaptureSessionManager

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
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }

    [self configConnection];
}

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
