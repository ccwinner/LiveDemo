//
//  CCWQueueOperationHelper.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/29.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#ifndef CCWQueueOperationHelper_h
#define CCWQueueOperationHelper_h

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN void asyncToVideoProcessorQueue(dispatch_block_t handler);
FOUNDATION_EXTERN void syncToVideoProcessorQueue(dispatch_block_t handler);

#endif /* CCWQueueOperationHelper_h */
