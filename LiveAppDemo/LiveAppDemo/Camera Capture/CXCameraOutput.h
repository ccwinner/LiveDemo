//
//  CXCameraOutput.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class AVCaptureVideoDataOutput, AVCaptureSession;

NS_ASSUME_NONNULL_BEGIN

@interface CXCameraOutput : NSObject
@property (nonatomic, readonly) AVCaptureVideoDataOutput *capturedDeviceOutput;
@property (nonatomic, copy) void (^didOutputData)(CMSampleBufferRef sampleBuffer, AVCaptureConnection *connection);
- (instancetype)initWithSession:(AVCaptureSession *)session;
- (void)useVideoOutputOfYUV;
@end

NS_ASSUME_NONNULL_END
