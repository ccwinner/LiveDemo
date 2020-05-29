//
//  ViewController.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/17.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
#import "CXCaptureSessionManager.h"
#import <AVFoundation/AVFoundation.h>

#import "CCWDisplayView.h"
#import "CCWVideoFilterAdapter.h"
#import "CCWQueueOperationHelper.h"

#import <GPUImage/GPUImage.h>

@interface ViewController ()<CCWCaptureSessionDelegate>
@property (nonatomic, strong) CXCaptureSessionManager *captureManager;

@property (nonatomic, strong) UIButton *runBtn;
@property (nonatomic, strong) UIButton *flipBtn;
@property (nonatomic, assign) BOOL front;
@property (nonatomic, assign) BOOL isRuning;

@property (nonatomic, strong) CCWDisplayView *displayView;
@property (nonatomic, strong) CCWVideoFilterAdapter *adapter;

@property (nonatomic, strong) dispatch_semaphore_t frameRenderingSemaphore;

@property (nonatomic, strong) GPUImageVideoCamera *gpuCamera;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = UIColor.whiteColor;
    self.frameRenderingSemaphore = dispatch_semaphore_create(1);

    [CXCaptureSessionManager requestCameraPermission:^(BOOL granted) {
        if (!granted) {
            return;
        }
        [self onGranted];
    }];
    
    self.front = YES;
}

- (void)onGranted {
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.captureManager = ({
            CXCaptureSessionManager *manager = [CXCaptureSessionManager manager];
            [manager setupSession];
            manager.videoLayer.frame = self.view.bounds;
            manager.delegate = self;
            manager;
        });

//        self.adapter = [CCWVideoFilterAdapter new];
//        self.adapter.sampeFormat = CCWVideoSampleFormatFullRangeYUV;
//        [self.adapter setupAdapter];

        self.displayView = ({
            CCWDisplayView *view = [[CCWDisplayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            [self.view addSubview:view];
            view;
        });
//        [self.displayView mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.edges.mas_offset(0);
//        }];

//        [self.adapter addDisplayView:self.displayView];

        self.runBtn = [UIButton new];
        [self.view addSubview:self.runBtn];
        [self.runBtn setTitle:@"采集" forState:UIControlStateNormal];
        [self.runBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [self.runBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(50, 24));
            make.bottom.offset(-30);
            make.left.offset(80);
        }];

        self.flipBtn = [UIButton new];
        [self.view addSubview:self.flipBtn];
        [self.flipBtn setTitle:@"翻转镜头" forState:UIControlStateNormal];
        [self.flipBtn setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [self.flipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(80, 24));
            make.bottom.offset(-30);
            make.right.offset(-80);
        }];
        [self.runBtn addTarget:self action:@selector(run) forControlEvents:UIControlEventTouchUpInside];
        [self.flipBtn addTarget:self action:@selector(flip) forControlEvents:UIControlEventTouchUpInside];
    });

    //使用gpuimage
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
//        videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//        self.gpuCamera = videoCamera;
//
////        GPUImageFilter *customFilter = [[GPUImageFilter alloc] initWithFragmentShaderFromFile:@"CustomShader"];
//        GPUImageView *filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
//
//        [self.view addSubview:filteredVideoView];
//        // Add the view somewhere so it's visible
//
//        [videoCamera addTarget:filteredVideoView];
////        [customFilter addTarget:filteredVideoView];
//
//        [videoCamera startCameraCapture];
//    });

}

- (void)run {
    if (!self.isRuning) {
        [self.captureManager startCapture];
        self.isRuning = YES;
    } else {
        [self.captureManager stopCapture];
        self.isRuning = NO;
    }
}

- (void)flip {
    self.front = !self.front;
    [self.captureManager flipCameraToFront:self.front];
}

#pragma mark - Delegate
- (void)outputSamplebuffer:(CMSampleBufferRef)sampleBuffer {
    if (dispatch_semaphore_wait(self.frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }

//    CFRetain(sampleBuffer);
//    asyncToVideoProcessorQueue(^{
//        [self.adapter processVideoSampleBuffer:sampleBuffer];

//        CFRelease(sampleBuffer);
//        dispatch_semaphore_signal(self.frameRenderingSemaphore);
//    });

        CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.displayView drawBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
        dispatch_semaphore_signal(self.frameRenderingSemaphore);
    });

}

@end
