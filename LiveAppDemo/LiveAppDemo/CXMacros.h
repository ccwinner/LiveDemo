//
//  CXMacros.h
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/18.
//  Copyright © 2020 com.liveDemo. All rights reserved.
//

#ifndef CXMacros_h
#define CXMacros_h

#import <Foundation/Foundation.h>

#ifndef dispatch_queue_async_safe
#define dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block) dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#endif /* CXMacros_h */
