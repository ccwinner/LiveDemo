//
//  CCWVideoFilterAdapter.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/24.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import "CCWVideoFilterAdapter.h"
#import "CCWVideoSharedContext.h"
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreFoundation/CoreFoundation.h>
#import "CCWQueueOperationHelper.h"

//#import <fstream>
//#import <string>

//using std::ifstream;
//using std::string;

//#import <GPUImage.h>

typedef struct CCWFillterAdapterTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} CCWFillterAdapterTextureOptions;

const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

// BT.601 full range (ref: http://www.equasys.de/colorconversion.html)
const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

@interface CCWVideoFilterAdapter () {
    GLuint _conversionProgram;
    GLuint currentProgram;
    
    GLuint vertexShader, conversionFragShader;
    GLuint positionLoc, inputTextureCoordinateLoc;
    GLint luminanceTextureUniformLoc, chrominanceTextureUniformLoc, colorConversionMatrixUniformLoc;

    GLuint luminanceTexture, chrominanceTexture;
    
    const GLfloat *colorConversionMatrixPtr;
    
    GLuint outputFramebuffer;
    
    size_t frameWidth, frameHeight;

    CVPixelBufferRef outputPixelBufferRef;
    CVOpenGLESTextureRef outputRenderTextureRef;
    GLuint outputRenderTexture;
    
    CCWFillterAdapterTextureOptions defaultTextureOptions;
}

@property (nonatomic, readonly) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, readonly) EAGLContext *glContext;
@property (nonatomic, weak) CCWDisplayView *weakDisplayView;

//@property (nonatomic, strong) GPUImageVideoCamera *tmpVideocamera;
@end

@implementation CCWVideoFilterAdapter

- (instancetype)init {
    if (self = [super init]) {
        //默认
        _sampeFormat = CCWVideoSampleFormatFullRangeYUV;

        //配置默认纹理选项
        defaultTextureOptions.minFilter = GL_LINEAR;
        defaultTextureOptions.magFilter = GL_LINEAR;
        defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
        defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
        defaultTextureOptions.internalFormat = GL_RGBA;
        defaultTextureOptions.format = GL_BGRA;
        defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    }
    return self;
}

//这个方法在单独线程处理,这个线程创建了一个glcontext。防止context重叠导致显示有错.
//多个context如果设置了shareGroup,可以共存
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{

    [self userVideoProcessContextAndConversionProgram];
    
    //绑texture
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);

    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    size_t bufferWidth = CVPixelBufferGetWidth(cameraFrame);
    size_t bufferHeight = CVPixelBufferGetHeight(cameraFrame);
    frameWidth = bufferWidth; frameHeight = bufferHeight;

    CFTypeRef colorAttachments = CVBufferGetAttachment(cameraFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL) {
        if(CFStringCompare((CFStringRef)colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
            if (self.sampeFormat == CCWVideoSampleFormatFullRangeYUV) {
                self->colorConversionMatrixPtr = kColorConversion601FullRange;
            } else {
                 self->colorConversionMatrixPtr = kColorConversion601;
            }
        } else {
             self->colorConversionMatrixPtr = kColorConversion709;
        }
    } else {
        if (self.sampeFormat == CCWVideoSampleFormatFullRangeYUV) {
             self->colorConversionMatrixPtr = kColorConversion601FullRange;
        } else {
             self->colorConversionMatrixPtr = kColorConversion601;
        }
    }
    
    //亮度 ref
    CVOpenGLESTextureRef luminanceTextureRef = NULL;

    CVReturn lerr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);

    if (lerr) {
        NSLog(@"--------txtCache l error");
    }

    //name相当于系统使用glGenTexture生成对应的材质id
    GLuint lumTextName = CVOpenGLESTextureGetName(luminanceTextureRef);
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, lumTextName);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    self->luminanceTexture = lumTextName;

    //色度 ref
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;

    CVReturn cerr = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);

    if (cerr) {
        NSLog(@"--------txtCache c error");
    }

    //name相当于系统使用glGenTexture生成对应的材质id
    GLuint chumTextName = CVOpenGLESTextureGetName(chrominanceTextureRef);
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chumTextName);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    self->chrominanceTexture = chumTextName;

    [self generateOutputFramebufferIfNeeded];
    [self activateOutputFramebuffer];

    //yuv to rgb
    //todo:如果屏幕被旋转过 帧的宽高就要颠倒过来
    [self convertYUVToRGBOutput];

    //传给显示view
    [self.weakDisplayView setupOutputFramebuffer:self->outputFramebuffer];
    [self.weakDisplayView updateFrameImageSize:CGSizeMake(bufferWidth, bufferHeight)];
    [self.weakDisplayView drawFrameTextureIndex:4 texture:self->outputRenderTexture];
    
    //恢复上下文
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    CFRelease(luminanceTextureRef);
    CFRelease(chrominanceTextureRef);
}

#pragma mark - Logic
- (void)generateOutputFramebufferIfNeeded {
    if (self->outputFramebuffer != 0) {
        return;
    }
        //绑定后的句柄应该是个非零值.
        //framebuffer相当于一块存储器, shader的结果最后会存到framebuffer中
        //可以缓存framebuffer防止多次创建, 缓存查找的key需要由frame size，纹理配置决定。
        //纹理配置参考
        /**
         typedef struct GPUTextureOptions {
             GLenum minFilter;
             GLenum magFilter;
             GLenum wrapS;
             GLenum wrapT;
             GLenum internalFormat;
             GLenum format;
             GLenum type;
         } GPUTextureOptions;
         */
    
    glGenFramebuffers(1, &outputFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, outputFramebuffer);
    
    CVOpenGLESTextureCacheRef texCacheRef = [self textureCache];

    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, frameWidth, frameHeight, kCVPixelFormatType_32BGRA, attrs, &outputPixelBufferRef);
    if (err) {
        NSAssert(NO, @"创建输出pixelBuffer图片失败");
        return;
    }

    //创建纹理,这个纹理不仅是conversionToRGB的载体，也是后续filter的输出对象
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, texCacheRef, outputPixelBufferRef, NULL, GL_TEXTURE_2D, defaultTextureOptions.internalFormat, frameWidth, frameHeight, defaultTextureOptions.format, defaultTextureOptions.type, 0, &outputRenderTextureRef);
    if (err) {
        NSAssert(NO, @"CVOpenGLESTextureCacheCreateTextureFromImage in 创建输出帧缓冲失败");
        return;
    }
    
    CFRelease(attrs);
    CFRelease(empty);

    glBindTexture(CVOpenGLESTextureGetTarget(outputRenderTextureRef), CVOpenGLESTextureGetName(outputPixelBufferRef));
    outputRenderTexture = CVOpenGLESTextureGetName(outputRenderTextureRef);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, defaultTextureOptions.wrapS);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, defaultTextureOptions.wrapT);
    
    //将纹理和帧缓冲绑定，缓冲类型是颜色缓冲
    //帧缓冲可以带纹理，或者带渲染缓冲。这里的帧缓冲类似离屏渲染,因为渲染是在屏幕之外完成。
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputRenderTexture, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"outputFrameBuffer流程没走全");
    
    //恢复上下文
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)activateOutputFramebuffer {
    glBindBuffer(GL_FRAMEBUFFER, outputFramebuffer);
    glViewport(0, 0, frameWidth, frameHeight);
}

/// Convert YUV/BGRA -> RGBA
- (void)convertYUVToRGBOutput {
    static const GLfloat areaVertices[] = {
       -1.0f, -1.0f,
       1.0f, -1.0f,
       -1.0f,  1.0f,
       1.0f,  1.0f,
    };
    //先按照竖屏前置摄像头处理
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    /*
     硬件设备采集到的的输出格式是yuv或者bgra，opengl渲染支持rgba，所以要转下。
     **/
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
    glUniform1ui(luminanceTextureUniformLoc, 4); //如果用的第零号单元，这是默认单元 就不用显示指定层数
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
    glUniform1ui(chrominanceTextureUniformLoc, 5); //如果用的第零号单元，这是默认单元

    glUniformMatrix3fv(colorConversionMatrixUniformLoc, 1, GL_FALSE, colorConversionMatrixPtr);
    //todo:根据屏幕旋转情况,改变纹理坐标
    //现在默认都是竖屏吧
    //position在顶点着色器的位置是0
    glVertexAttribPointer(positionLoc, 2, GL_FLOAT, 0, 0, areaVertices);
    glVertexAttribPointer(inputTextureCoordinateLoc, 2, GL_FLOAT, 0, 0, rotateRightVerticalFlipTextureCoordinates);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

#pragma mark - texture cache
- (CVOpenGLESTextureCacheRef)textureCache {
    return [[CCWVideoSharedContext context] textureCache];
}

- (EAGLContext *)glContext;
{
    return [[CCWVideoSharedContext context] glContext];
}

- (void)setupAdapter {
    [self prepareWorkForConversion];
}

#pragma mark - Private
- (void)prepareWorkForConversion {
    
    syncToVideoProcessorQueue(^{

        [self glContext];

        self->_conversionProgram = glCreateProgram();
        self->currentProgram = self->_conversionProgram;

        
        NSString *vsPath = nil;
        NSString *yuvPath = nil;
        
        if (self.sampeFormat == CCWVideoSampleFormatFullRangeYUV) {
            vsPath = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"];
            yuvPath = [[NSBundle mainBundle] pathForResource:@"YuvConversionFullRange" ofType:@"fsh"];
        } else if (self.sampeFormat == CCWVideoSampleFormatYUV) {
            vsPath = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"];
            yuvPath = [[NSBundle mainBundle] pathForResource:@"YuvConversionYUV" ofType:@"fsh"];
        }
        
        self->vertexShader = [self buildShaderProgramForPath:vsPath type:GL_VERTEX_SHADER];
        self->conversionFragShader = [self buildShaderProgramForPath:yuvPath type:GL_FRAGMENT_SHADER];

        self->positionLoc = 0; self->inputTextureCoordinateLoc = 1;

        //告诉opGL每个数据的索引 -----替代方法是在shader中用layout()指定
        glBindAttribLocation(self->_conversionProgram, self->positionLoc, "position");
        glBindAttribLocation(self->_conversionProgram, self->inputTextureCoordinateLoc, "inputTextureCoordinate");
        //link program
        glLinkProgram(self->_conversionProgram);
        GLint status = 0;
        glGetProgramiv(self->_conversionProgram, GL_LINK_STATUS, &status);
        if (status == GL_FALSE) {
            NSLog(@"link program error");
        }
        
        //free 资源
        if (self->vertexShader) {
            glDeleteShader(self->vertexShader);
        }
        if (self->conversionFragShader) {
            glDeleteShader(self->conversionFragShader);
        }

        //获取每个变量在shader的位置
        GLuint programI = self->_conversionProgram;
    
        self->luminanceTextureUniformLoc = glGetUniformLocation(programI, "luminanceTexture");
        self->chrominanceTextureUniformLoc = glGetUniformLocation(programI, "chrominanceTexture");
        self->colorConversionMatrixUniformLoc = glGetUniformLocation(programI, "colorConversionMatrix");
        
        glUseProgram(programI);

        glEnableVertexAttribArray(self->positionLoc);
        glEnableVertexAttribArray(self->inputTextureCoordinateLoc);

        [self userVideoProcessContextAndConversionProgram];
    });

}

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
    glAttachShader(_conversionProgram, shader);
    return shader;

}

- (void)useVideoProcessingContext {
    [[CCWVideoSharedContext context] useVideoProcessingContext];
}

- (void)userVideoProcessContextAndConversionProgram {
    [[CCWVideoSharedContext context] setContextProgram:_conversionProgram];
}

#pragma mark - Display
- (void)addDisplayView:(CCWDisplayView *)view {
    self.weakDisplayView = view;
}

#pragma mark - free
- (void)dealloc {
    syncToVideoProcessorQueue(^{
        if (self->outputFramebuffer != 0) {
            glDeleteFramebuffers(1, &self->outputFramebuffer);
        }
        if (self->outputPixelBufferRef) {
            CFRelease(self->outputPixelBufferRef);
        }
        if (self->outputRenderTextureRef) {
            CFRelease(self->outputRenderTextureRef);
        }
        
    });
}

@end
