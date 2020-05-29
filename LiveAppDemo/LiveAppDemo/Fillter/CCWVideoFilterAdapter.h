//
//  CCWVideoFilterAdapter.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/24.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import "CCWDisplayView.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, CCWVideoSampleFormat) {
    CCWVideoSampleFormatFullRangeYUV,
    CCWVideoSampleFormatYUV
};

@interface CCWVideoFilterAdapter : NSObject

@property (nonatomic, assign) CCWVideoSampleFormat sampeFormat;

- (void)setupAdapter;

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)addDisplayView:(CCWDisplayView*)view;

@end

NS_ASSUME_NONNULL_END
