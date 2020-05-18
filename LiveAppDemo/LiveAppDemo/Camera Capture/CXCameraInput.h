//
//  CXCameraInput.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/17.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AVCaptureDeviceInput, AVCaptureSession, AVCaptureDevice;

NS_ASSUME_NONNULL_BEGIN

@interface CXCameraInput : NSObject
@property (nonatomic, assign, readonly) NSInteger currentPosition;
@property (nonatomic, readonly) AVCaptureDeviceInput *capturedDeviceInput;
@property (nonatomic, readonly) AVCaptureDevice *camera;

- (instancetype)initWithSession:(AVCaptureSession *)session;
- (void)prepareForInput;

@end

NS_ASSUME_NONNULL_END
