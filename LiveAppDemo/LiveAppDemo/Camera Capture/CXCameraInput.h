//
//  CXCameraInput.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/17.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CXCameraInput : NSObject
@property (nonatomic, assign, readonly) NSInteger currentPosition;
@property (nonatomic, readonly) AVCaptureDeviceInput *capturedDeviceInput;
@property (nonatomic, readonly) AVCaptureDevice *camera;

- (instancetype)initWithSession:(AVCaptureSession *)session;
- (void)prepareForInput;
- (void)useCameraPosition:(AVCaptureDevicePosition)position;

@end

NS_ASSUME_NONNULL_END
