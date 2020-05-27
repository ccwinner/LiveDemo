//
//  CCWDisplayView.m
//  LiveAppDemo
//
//  Created by ccwinner on 2020/5/27.
//  Copyright © 2020 com.LiveDemo. All rights reserved.
//

#import "CCWDisplayView.h"
#import <GLKit/GLKit.h>

@implementation CCWDisplayView

#pragma mark - Override
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        //todo:setup context program shader format
    }
    return self;
}

@end
