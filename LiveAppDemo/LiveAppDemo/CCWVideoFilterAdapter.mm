//
//  CCWVideoFilterAdapter.m
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/24.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import "CCWVideoFilterAdapter.h"
#import "CCWVideoSharedContext.h"
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES2/glext.h>

//#import <fstream>
//#import <string>

//using std::ifstream;
//using std::string;

//#import <GPUImage.h>

@interface CCWVideoFilterAdapter () {
    GLuint _program;
}
@property (nonatomic) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic) EAGLContext *glContext;

//@property (nonatomic, strong) GPUImageVideoCamera *tmpVideocamera;
@end

void asyncToVideoProcessorQueue(dispatch_block_t handler) {
    if (dispatch_get_specific(videoProcessQKey)) {
        handler();
    } else {
        dispatch_async([[CCWVideoSharedContext context] videoProcessQueue], handler);
    }
}

@implementation CCWVideoFilterAdapter

- (instancetype)init {
    if (self = [super init]) {
        [self prepareWork];
    }
    return self;
}

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    //todo:绑定shader 构建上下文

    //绑texture
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);

    //亮度 ref
    CVOpenGLESTextureRef luminanceTextureRef = NULL;

    CVReturn lerr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);

    if (lerr) {
        NSLog(@"--------txtCache l error");
    }

    //name相当于系统使用glGenTexture生成对应的材质id
    GLuint lumTextName = CVOpenGLESTextureGetName(luminanceTextureRef);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, lumTextName);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    //色度 ref
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;

    CVReturn cerr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth, bufferHeight, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);

    if (cerr) {
        NSLog(@"--------txtCache c error");
    }

    //name相当于系统使用glGenTexture生成对应的材质id
    GLuint chumTextName = CVOpenGLESTextureGetName(chrominanceTextureRef);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, chumTextName);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);


}

//#pragma mark - GPUImage
//- (GPUImageVideoCamera *)tmpVideocamera {
//    if (_tmpVideocamera) {
//        _tmpVideocamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
//        __auto_type filter = [GPUImageBilateralFilter new];
//        [_tmpVideocamera addTarget:filter];
//        [filter addTarget:(GPUImageView *)self.view];
//
//    }
//    return _tmpVideocamera;
//}

#pragma mark - texture cache
- (CVOpenGLESTextureCacheRef)textureCache {
    if (!_textureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_textureCache);
        if (err) {
            NSLog(@"openglES txt cache create failed");
        }
    }
    return _textureCache;
}

- (EAGLContext *)glContext;
{
    if (_glContext == nil)
    {
        _glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_glContext];
        //不需要3d
        glDisable(GL_DEPTH_TEST);
    }

    return _glContext;
}

#pragma mark - Private
- (void)prepareWork {
    [self glContext];


    _program = glCreateProgram();


    NSString *vsPath = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"];
    NSString *yuvPath = [[NSBundle mainBundle] pathForResource:@"YuvFullRange" ofType:@"fsh"];
    [self parseShaderProgramForPath:vsPath];
    [self parseShaderProgramForPath:yuvPath];

}

- (void)parseShaderProgramForPath:(NSString *)path {
    const char *shaderL = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil].UTF8String;
        GLuint shader = glCreateShader(GL_VERTEX_SHADER);
    const GLchar *source = (GLchar *)shaderL;
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        NSLog(@"failed to add shader:%@",path);
    }
    glAttachShader(_program, shader);

}


@end
