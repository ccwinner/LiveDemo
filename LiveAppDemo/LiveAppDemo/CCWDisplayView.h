//
//  CCWDisplayView.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/27.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCWDisplayView : UIView
- (void)updateFrameImageSize:(CGSize)imageSize;
- (void)setupOutputFramebuffer:(GLuint)outputFramebuffer;
- (void)drawFrameTextureIndex:(int)textureIndex texture:(GLuint)texture;

- (void)drawBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
