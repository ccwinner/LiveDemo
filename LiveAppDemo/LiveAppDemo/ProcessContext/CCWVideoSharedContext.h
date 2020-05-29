//
//  CCWVideoSharedContext.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/24.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN const char *videoProcessQKey;

@interface CCWVideoSharedContext : NSObject
+ (instancetype)context;

@property (nonatomic, readonly) dispatch_queue_t videoProcessQueue;

- (EAGLContext *)glContext;
- (CVOpenGLESTextureCacheRef)textureCache;
- (void)useVideoProcessingContext;
/// glprogram 可以封装一下
- (void)setContextProgram:(GLuint)glprogram;
@end

NS_ASSUME_NONNULL_END
