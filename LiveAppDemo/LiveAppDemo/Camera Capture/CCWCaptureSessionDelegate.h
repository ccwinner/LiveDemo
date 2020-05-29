//
//  CCWCaptureSessionDelegate.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/29.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CCWCaptureSessionDelegate <NSObject>
- (void)outputSamplebuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
