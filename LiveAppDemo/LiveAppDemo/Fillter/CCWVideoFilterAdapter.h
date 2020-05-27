//
//  CCWVideoFilterAdapter.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/24.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, CCWVideoSampleFormat) {
    CCWVideoSampleFormatFullRangeYUV,
    CCWVideoSampleFormatYUV
};

@interface CCWVideoFilterAdapter : NSObject

FOUNDATION_EXTERN void asyncToVideoProcessorQueue(dispatch_block_t handler);
FOUNDATION_EXTERN void syncToVideoProcessorQueue(dispatch_block_t handler);

@property (nonatomic, assign) CCWVideoSampleFormat sampeFormat;

- (void)setupAdapter;

- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
