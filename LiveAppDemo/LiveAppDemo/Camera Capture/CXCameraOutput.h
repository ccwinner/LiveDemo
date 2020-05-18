//
//  CXCameraOutput.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVCaptureVideoDataOutput, AVCaptureSession;

NS_ASSUME_NONNULL_BEGIN

@interface CXCameraOutput : NSObject
@property (nonatomic, readonly) AVCaptureVideoDataOutput *capturedDeviceOutput;
- (instancetype)initWithSession:(AVCaptureSession *)session;
@end

NS_ASSUME_NONNULL_END
