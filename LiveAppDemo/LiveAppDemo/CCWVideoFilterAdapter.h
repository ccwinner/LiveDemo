//
//  CCWVideoFilterAdapter.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/24.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCWVideoFilterAdapter : NSObject

FOUNDATION_EXTERN void asyncToVideoProcessorQueue(dispatch_block_t handler);
- (void)processVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
