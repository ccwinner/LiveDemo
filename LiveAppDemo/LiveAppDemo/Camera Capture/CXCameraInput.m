//
//  CXCameraInput.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/17.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CXCameraInput.h"
#import "CXMacros.h"
#import <AVFoundation/AVFoundation.h>

@interface CXCameraInput ()
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) AVCaptureDeviceInput *capturedDeviceInput;
@property (nonatomic, assign) NSInteger currentPosition;
@end


@implementation CXCameraInput

- (instancetype)initWithSession:(AVCaptureSession *)session {
    if (self = [super init]) {
        _session = session;
        _serialQueue = dispatch_queue_create("com.camera.input", NULL);
        
    }
    return self;
}

- (void)startCapture {
    dispatch_queue_async_safe(self.serialQueue, ^{
        [self.session startRunning];
    });
}

- (void)prepareForInput {
    [self useCameraPosition:AVCaptureDevicePositionFront];
}

- (void)useCameraPosition:(AVCaptureDevicePosition)position {
    if (self.currentPosition == position) {
        return;
    }
    self.currentPosition = position;

    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *frontCamera = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", self.currentPosition]].firstObject;
    if (!frontCamera) {
        NSLog(@"获取前置摄像头失败");
        return;
    }

    NSError *error;
    self.capturedDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
    if (error) {
        NSLog(@"获取deviceInput失败了");
        return;
    }
}

#pragma mark - Private


@end
