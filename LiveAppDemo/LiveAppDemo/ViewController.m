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

@interface ViewController ()
@property (nonatomic, strong) CXCaptureSessionManager *captureManager;

@property (nonatomic, strong) UIButton *runBtn;
@property (nonatomic, strong) UIButton *flipBtn;
@property (nonatomic, assign) BOOL front;
@property (nonatomic, assign) BOOL isRuning;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = UIColor.whiteColor;

    [CXCaptureSessionManager requestCameraPermission:^(BOOL granted) {
        if (!granted) {
            return;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.captureManager = ({
                CXCaptureSessionManager *manager = [CXCaptureSessionManager manager];
                [manager setupSession];
                manager.videoLayer.frame = self.view.bounds;
                manager;
            });
            [self.view.layer addSublayer:self.captureManager.videoLayer];

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
    }];
    
    self.front = YES;
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

@end
