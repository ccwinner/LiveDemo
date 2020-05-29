//
//  CCWVideoSharedContext.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/24.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import "CCWVideoSharedContext.h"

const char *videoProcessQKey = "com.ccw.videoProcessQKey";

@interface CCWVideoSharedContext () {
    CVOpenGLESTextureCacheRef _textureCache;
    GLuint _currentProgram;
}

@property (nonatomic, strong) dispatch_queue_t videoProcessQueue;

@property (nonatomic, strong) EAGLContext *glContext;
@end

@implementation CCWVideoSharedContext

void asyncToVideoProcessorQueue(dispatch_block_t handler) {
    if (dispatch_get_specific(videoProcessQKey)) {
        handler();
    } else {
        dispatch_async([[CCWVideoSharedContext context] videoProcessQueue], handler);
    }
}

void syncToVideoProcessorQueue(dispatch_block_t handler) {
    if (dispatch_get_specific(videoProcessQKey)) {
        handler();
    } else {
        dispatch_sync([[CCWVideoSharedContext context] videoProcessQueue], handler);
    }
}

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

- (EAGLContext *)glContext;
{
    if (_glContext == nil)
    {
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_glContext];

        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }

    return _glContext;
}

- (CVOpenGLESTextureCacheRef)textureCache {
    if (!_textureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_textureCache);
        if (err) {
            NSLog(@"openglES txt cache create failed");
        }
    }
    return _textureCache;
}

- (void)useVideoProcessingContext {
    if ([EAGLContext currentContext] != [self glContext]) {
        [EAGLContext setCurrentContext:[self glContext]];
    }
}

- (void)setContextProgram:(GLuint)glprogram {
    [self useVideoProcessingContext];
    if (_currentProgram != glprogram) {
        _currentProgram = glprogram;
        glUseProgram(_currentProgram);
    }
}

@end
