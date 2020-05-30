//
//  CCWDisplayView.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/27.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import "CCWDisplayView.h"
#import <GLKit/GLKit.h>
#import "CCWQueueOperationHelper.h"
#import "CCWVideoSharedContext.h"
#import <AVFoundation/AVFoundation.h>

@interface CCWDisplayView () {
    GLint positionLocation, inputTextureCoordinateLocation;
    GLint inputTextureUniform;
    GLuint framebuffer, renderbuffer;

    GLuint outputFramebuffer;

    CGFloat widthPixels, heightPixels;
    CGSize initialSize, inputImageSize;

    GLfloat imageVertices[8];


    //complement
    GLint _luminanceTextureAtt, _chrominanceTextureAtt, _colorConversionMatrixAtt;
    GLsizei _bufferWidth, _bufferHeight;
    GLuint _luminanceTexture, _chrominanceTexture;
    CVOpenGLESTextureRef _luminanceTextureRef, _chrominanceTextureRef;
}

@property (nonatomic, assign) GLuint displayProgram;
@property (nonatomic, assign) GLuint vertexShader;
@property (nonatomic, assign) GLuint fragShader;
@end

@implementation CCWDisplayView

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
static const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

#pragma mark - Override
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        //todo:setup context program shader format

        CAEAGLLayer *glLayer = (CAEAGLLayer *)self.layer;
        glLayer.drawableProperties = @{
            kEAGLDrawablePropertyRetainedBacking : @(NO),
            kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8
        };

//        syncToVideoProcessorQueue(^{
            [[CCWVideoSharedContext context] useVideoProcessingContext];

            self.displayProgram = glCreateProgram();

            self.vertexShader = [self buildShaderProgramForPath:[[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"] type:GL_VERTEX_SHADER];
            self.fragShader = [self buildShaderProgramForPath:[[NSBundle mainBundle] pathForResource:@"YuvConversionFullRange" ofType:@"fsh"]
                               type:GL_FRAGMENT_SHADER];

            //在shader里使用layout (xx)的形式能免去这两行冗余处理
            glBindAttribLocation(self.displayProgram, 0, "position");
            glBindAttribLocation(self.displayProgram, 1, "inputTextureCoordinate");

            [self linkProgram];

//            self->positionLocation = 0; self->inputTextureCoordinateLocation = 1;
//            self->inputTextureUniform = glGetUniformLocation(self.displayProgram, "inputImageTexture");


            _luminanceTextureAtt = glGetUniformLocation(self.displayProgram, "luminanceTexture");
            _chrominanceTextureAtt = glGetUniformLocation(self.displayProgram, "chrominanceTexture");
            _colorConversionMatrixAtt = glGetUniformLocation(self.displayProgram, "colorConversionMatrix");

            glUseProgram(self.displayProgram);
            [self setupFramebuffer];
//        });
    }
    return self;
}

//- (void)updateFrameImageSize:(CGSize)imageSize {
//    //先不考虑转屏的情况
//    //todo:转屏以后交换imageSize的宽高
//    if (!CGSizeEqualToSize(inputImageSize, imageSize))
//    {
//        inputImageSize = imageSize;
//        [self updateImageVerticies];
//    }
//}
//
//- (void)setupOutputFramebuffer:(GLuint)outputFramebuffer {
//    outputFramebuffer = outputFramebuffer;
//}

- (void)drawFrameTextureIndex:(int)textureIndex texture:(GLuint)texture {
    //先按照竖屏f前置摄像头处理
//    static const GLfloat rotateRightTextureCoordinates[] = {
//        1.0f, 1.0f,
//        1.0f, 0.0f,
//        0.0f, 1.0f,
//        0.0f, 0.0f,
//    };
////    syncToVideoProcessorQueue(^{
//        [[CCWVideoSharedContext context] setContextProgram:self.displayProgram];
//
//        glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer);
//        glViewport(0, 0, (GLsizei)self->widthPixels, (GLsizei)self->heightPixels);
//
//        glClearColor(0, 0, 0, 1);
//        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//
//        glActiveTexture(GL_TEXTURE4);
////        GLint outputFramebufferTexture = -100;
////        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, &outputFramebufferTexture);
////        if (outputFramebufferTexture == -100) {
////            <#statements#>
////        }
//        glBindTexture(GL_TEXTURE_2D, texture);
//        glUniform1i(self->inputTextureUniform, 4);
//        glVertexAttribPointer(self->positionLocation, 2, GL_FLOAT, GL_FALSE, 0, self->imageVertices);
//        glVertexAttribPointer(self->inputTextureCoordinateLocation, 2, GL_FLOAT, GL_FALSE, 0, rotateRightTextureCoordinates);
//
//        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//
//        glBindRenderbuffer(GL_RENDERBUFFER, self->renderbuffer);
//        [[[CCWVideoSharedContext context] glContext] presentRenderbuffer:GL_RENDERBUFFER];
//    });
}

#pragma mark -
- (void)setupFramebuffer {
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

    glGenRenderbuffers(1, &renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);

    [[[CCWVideoSharedContext context] glContext] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];

    GLint backingWidth, backingHeight;

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);

    if ( (backingWidth == 0) || (backingHeight == 0) ) {
        [self destroyFramebuffers];
        NSLog(@"set render frame buffer return for invalid size");
        return;
    }
    widthPixels = backingWidth;
    heightPixels = backingHeight;

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    NSAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f", self.bounds.size.width, self.bounds.size.height);
//    initialSize = self.bounds.size;
}

- (void)destroyFramebuffers {
    if (framebuffer) {
        glDeleteFramebuffers(1, &framebuffer);
    }
    if (renderbuffer) {
        glDeleteRenderbuffers(1, &renderbuffer);
    }
}

- (void)updateImageVerticies {
//    syncToVideoProcessorQueue(^{
//        CGFloat heightScaling, widthScaling;
//
//        CGSize currentViewSize = self.bounds.size;
//
//        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(self->inputImageSize, self.bounds);

        //先默认保持原来的宽高比
//        switch(_fillMode)
//        {
//            case kGPUImageFillModeStretch:
//            {
//                widthScaling = 1.0;
//                heightScaling = 1.0;
//            }; break;
//            case kGPUImageFillModePreserveAspectRatio:
//            {
//                widthScaling = insetRect.size.width / currentViewSize.width;
//                heightScaling = insetRect.size.height / currentViewSize.height;
//            }; break;
//            case kGPUImageFillModePreserveAspectRatioAndFill:
//            {
//                //            CGFloat widthHolder = insetRect.size.width / currentViewSize.width;
//                widthScaling = currentViewSize.height / insetRect.size.height;
//                heightScaling = currentViewSize.width / insetRect.size.width;
//            }; break;
//        }

//        widthScaling = insetRect.size.width / currentViewSize.width;
//        heightScaling = insetRect.size.height / currentViewSize.height;
//
//        self->imageVertices[0] = -widthScaling;
//        self->imageVertices[1] = -heightScaling;
//        self->imageVertices[2] = widthScaling;
//        self->imageVertices[3] = -heightScaling;
//        self->imageVertices[4] = -widthScaling;
//        self->imageVertices[5] = heightScaling;
//        self->imageVertices[6] = widthScaling;
//        self->imageVertices[7] = heightScaling;
//    });
}

#pragma mark - Override
//- (void)layoutSubviews {
//    [super layoutSubviews];
//
//    if (/*!CGSizeEqualToSize(self.bounds.size, initialSize) &&*/
//        !CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
//        syncToVideoProcessorQueue(^{
//            [[CCWVideoSharedContext context] useVideoProcessingContext];
//
//            [self destroyFramebuffers];
//            [self setupFramebuffer];
//            [self updateImageVerticies];
//        });
//    }
//}

- (void)dealloc {
    syncToVideoProcessorQueue(^{
        [self destroyFramebuffers];
    });
}

#pragma mark - Private
//todo:待抽出
- (GLuint)buildShaderProgramForPath:(NSString *)path type:(GLenum)type {
    const char *shaderL = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil].UTF8String;
    GLuint shader = glCreateShader(type);
    const GLchar *source = (GLchar *)shaderL;
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE) {
        NSLog(@"failed to add shader:%@",path);
    }
    glAttachShader(self.displayProgram, shader);
    return shader;

}

- (void)linkProgram {
    glLinkProgram(self.displayProgram);
    GLint status = 0;
    glGetProgramiv(self.displayProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        NSCAssert(NO, @"link display shader 失败");
    }

    if (self.vertexShader)
    {
        glDeleteShader(self.vertexShader);
        self.vertexShader = 0;
    }
    if (self.fragShader)
    {
        glDeleteShader(self.fragShader);
        self.fragShader = 0;
    }
}

#pragma mark - Micro implementation

- (void)setupTexture:(CMSampleBufferRef)sampleBuffer
{
    // 获取图片信息
    CVImageBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);

    // 获取图片宽度
    GLsizei bufferWidth = (GLsizei)CVPixelBufferGetWidth(imageBufferRef);
    _bufferWidth = bufferWidth;
    GLsizei bufferHeight = (GLsizei)CVPixelBufferGetHeight(imageBufferRef);
    _bufferHeight = bufferHeight;


    // 创建亮度纹理
    // 激活纹理单元0, 不激活，创建纹理会失败
    glActiveTexture(GL_TEXTURE0);

    // 创建纹理对象
    CVReturn err;
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[CCWVideoSharedContext context] textureCache], imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &_luminanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _luminanceTexture = CVOpenGLESTextureGetName(_luminanceTextureRef);

    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _luminanceTexture);

    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // 设置纹理过滤
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

    // 激活单元1
    glActiveTexture(GL_TEXTURE1);

    // 创建色度纹理
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[CCWVideoSharedContext context] textureCache], imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth / 2, bufferHeight / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &_chrominanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _chrominanceTexture = CVOpenGLESTextureGetName(_chrominanceTextureRef);

    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);

    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // 设置纹理过滤
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

- (void)convertYUVToRGBOutput
{
    // 在创建纹理之前，有激活过纹理单元，就是那个数字.GL_TEXTURE0,GL_TEXTURE1
    // 指定着色器中亮度纹理对应哪一层纹理单元
    // 这样就会把亮度纹理，往着色器上贴
    glUniform1i(_luminanceTextureAtt, 0);

    // 指定着色器中色度纹理对应哪一层纹理单元
    glUniform1i(_chrominanceTextureAtt, 1);

    // YUV转RGB矩阵
    glUniformMatrix3fv(_colorConversionMatrixAtt, 1, GL_FALSE, kColorConversion601FullRange);

    // 计算顶点数据结构
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(self.bounds.size.width, self.bounds.size.height), self.layer.bounds);

    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/self.layer.bounds.size.width, vertexSamplingRect.size.height/self.layer.bounds.size.height);

    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }

    // 确定顶点数据结构
    //如果是全屏展示的情况 这里就是-1-1,1-1,-11,11
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };

    // 确定纹理数据结构
//    static GLfloat quadTextureData[] =  { // 正常坐标
//        0, 0,
//        1, 0,
//        0, 1,
//        1, 1
//    };
    //如果采用上面的纹理坐标  会发现画面颠倒了
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    // 激活ATTRIB_POSITION顶点数组
    glEnableVertexAttribArray(0);
    // 给ATTRIB_POSITION顶点数组赋值
    glVertexAttribPointer(0, 2, GL_FLOAT, 0, 0, quadVertexData);

    // 给ATTRIB_TEXCOORD顶点数组赋值
    glEnableVertexAttribArray(1);
    // 激活ATTRIB_TEXCOORD顶点数组
    glVertexAttribPointer(1, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);

    // 渲染纹理数据,注意一定要和纹理代码放一起
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)cleanUpTextures {
    // 清空亮度引用
    if (_luminanceTextureRef) {
        CFRelease(_luminanceTextureRef);
        _luminanceTextureRef = NULL;
    }

    // 清空色度引用
    if (_chrominanceTextureRef) {
        CFRelease(_chrominanceTextureRef);
        _chrominanceTextureRef = NULL;
    }

    // 清空纹理缓存
    CVOpenGLESTextureCacheFlush([[CCWVideoSharedContext context] textureCache], 0);

}

- (void)drawBuffer:(CMSampleBufferRef)sampleBuffer {
    // 因为是多线程，每一个线程都有一个上下文，只要在一个上下文绘制就好，设置线程的上下文为我们自己的上下文,就能绘制在一起了，否则会黑屏.
    [[CCWVideoSharedContext context] useVideoProcessingContext];

    // 清空之前的纹理，要不然每次都创建新的纹理，耗费资源，造成界面卡顿
    [self cleanUpTextures];

    // 创建纹理对象
    [self setupTexture:sampleBuffer];

    // YUV 转 RGB
    [self convertYUVToRGBOutput];

    // 设置窗口尺寸
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);

    // 把上下文的东西渲染到屏幕上
    [[[CCWVideoSharedContext context] glContext] presentRenderbuffer:GL_RENDERBUFFER];
}
@end
