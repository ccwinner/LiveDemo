//
//  CCWVideoSharedContext.h
//  LiveAppDemo
//
//  Created by chenxiao on 2020/5/24.
//  Copyright © 2020 com.kwai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN const char *videoProcessQKey;

@interface CCWVideoSharedContext : NSObject
+ (instancetype)context;

@property (nonatomic, readonly) dispatch_queue_t videoProcessQueue;
@end

NS_ASSUME_NONNULL_END
