//
//  CXCameraInput.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/17.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CXCameraInput.h"
#import <AVFoundation/AVFoundation.h>

@interface CXCameraInput ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@end


@implementation CXCameraInput

- (instancetype)init {
    if (self = [super init]) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return self;
}

- (void)startCapture {
    [self.captureSession startRunning];
}

@end
