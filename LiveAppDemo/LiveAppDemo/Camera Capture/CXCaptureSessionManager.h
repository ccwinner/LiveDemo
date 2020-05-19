//
//  CXCaptureSessionManager.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/18.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, CXCaptureResolutionType) {
    CXCaptureResolutionTypeLow,
    CXCaptureResolutionTypeMedium,
    CXCaptureResolutionTypeHigh,

    CXCaptureResolutionType720p,
    CXCaptureResolutionType1080p
};

@interface CXCaptureSessionManager : NSObject

@property (nonatomic, assign) NSInteger frameRate; //default is 30

+ (instancetype)manager;

- (void)setupSession;
- (void)startCapture;

- (void)flipCameraToFront:(BOOL)captureFront;
- (void)changeResolution:(CXCaptureResolutionType)type;
- (void)changeFrameRate:(NSInteger)frameRate;

@end

NS_ASSUME_NONNULL_END
