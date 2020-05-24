//
//  CCWVideoSharedContext.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/24.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CCWVideoSharedContext.h"

const char *videoProcessQKey = "com.ccw.videoProcessQKey";

@interface CCWVideoSharedContext ()
@property (nonatomic, strong) dispatch_queue_t videoProcessQueue;
@end

@implementation CCWVideoSharedContext

+ (instancetype)context {
    static CCWVideoSharedContext *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CCWVideoSharedContext new];
    });
    return instance;
}

- (dispatch_queue_t)videoProcessQueue {
    if (!_videoProcessQueue) {
        _videoProcessQueue = dispatch_queue_create("com.ccw.videprocess", NULL);
        dispatch_queue_set_specific(_videoProcessQueue, videoProcessQKey, NULL, NULL);
    }
    return _videoProcessQueue;
}

@end
