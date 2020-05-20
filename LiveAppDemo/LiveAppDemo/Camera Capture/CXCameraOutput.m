//
//  CXCameraOutput.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#import "CXCameraOutput.h"
#import <CoreVideo/CoreVideo.h>

@interface CXCameraOutput ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureVideoDataOutput *capturedDeviceOutput;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@end

@implementation CXCameraOutput

- (instancetype)initWithSession:(AVCaptureSession *)session{
    if (self = [super init]) {
        _session = session;
        _serialQueue = dispatch_queue_create("com.cameraOutput", NULL);
    }
    return self;
}

//YUV比RGB更节省内存
- (void)useVideoOutputOfYUV {
    self.capturedDeviceOutput = ({
        __auto_type output = [AVCaptureVideoDataOutput new];

        //这样设置用于高清了
        [output setVideoSettings:@{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        }];
        [output setSampleBufferDelegate:self queue:self.serialQueue];

        //丢弃来不及处理的帧,否则内存消耗大
        output.alwaysDiscardsLateVideoFrames = YES;
        output;
    });
}

#pragma mark - Output Delegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    if (self.didOutputData) {
        self.didOutputData(sampleBuffer, connection);
    }
}

@end
