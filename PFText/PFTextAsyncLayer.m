//
//  PFTextAsyncLayer.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2017/8/10.
//  Copyright © 2017年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextAsyncLayer.h"
#import <libkern/OSAtomic.h>
#import <stdatomic.h>

static dispatch_queue_t _pf_textLayerDsipalyerQueue(){
#define _PF_DISPLAY_MAX_QUEUE 16
    static int queueCount = 0;
    static atomic_int counter = 0;
    static dispatch_queue_t queues[_PF_DISPLAY_MAX_QUEUE];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > _PF_DISPLAY_MAX_QUEUE ? _PF_DISPLAY_MAX_QUEUE : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
                queues[i] = dispatch_queue_create("com.ibireme.text.render", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.ibireme.text.render", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            }
        }
    });
    
    atomic_int cur = atomic_fetch_add_explicit(&counter,1,memory_order_relaxed);
    return queues[(cur)%queueCount];
#undef _PF_DISPLAY_MAX_QUEUE
}

@interface _PFTextSentinel : NSObject

@property (atomic, readonly) atomic_int value;

- (atomic_int)increase;

@end

@implementation _PFTextSentinel
{
    atomic_int _value;
}

- (int)value
{
    return _value;
}

- (atomic_int)increase {
    return atomic_fetch_add_explicit(&_value,1,memory_order_relaxed);
}

@end

@interface PFTextAsyncLayer ()
{
    _PFTextSentinel *_sentinel;
}


@end

@implementation PFTextAsyncLayer

- (instancetype)init
{
    if (self = [super init]) {
        _sentinel = [_PFTextSentinel new];
        _displaysAsynchronously = YES;
    }
    return self;
}

- (void)setNeedsDisplay
{
    [self _cancelAsyncDisplay];
    [super setNeedsDisplay];
}

- (void)display
{
    //设置当前contents为super contents
    super.contents = super.contents;
    [self _displayAsync:_displaysAsynchronously];
}

- (void)_displayAsync:(BOOL)async
{
    _PFTextSentinel *sentiel = _sentinel;
    __strong id<PFTextAsyncLayerDelegate>delegate = self.asyncLayerDelegate;

    NSAssert(self.asyncLayerDelegate, @"asyncLayerDelegate属性错误");
    
    if (async) {
        
        if ([delegate respondsToSelector:@selector(layerWillDisplay:)]) {
            [delegate layerWillDisplay:self];
        }
        atomic_int thisValue = sentiel.value;
        BOOL (^isSuspended)() = ^BOOL() {
            return thisValue != sentiel.value;
        };
        
        dispatch_async(_pf_textLayerDsipalyerQueue(), ^{
           
            if (isSuspended()) {
                return;
            }
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            if ([delegate respondsToSelector:@selector(layerDispaly:size:isSuspended:)]) {
                [delegate layerDispaly:context size:CGSizeZero isSuspended:isSuspended];
            }
            if (isSuspended()) {
                UIGraphicsEndImageContext();
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(layerDisplayCompletion:finish:)]) {
                        [delegate layerDisplayCompletion:self finish:NO];
                    }
                });
                return;
            }
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if (isSuspended()) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([delegate respondsToSelector:@selector(layerDisplayCompletion:finish:)]) {
                        [delegate layerDisplayCompletion:self finish:NO];
                    }
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isSuspended()) {
                    if ([delegate respondsToSelector:@selector(layerDisplayCompletion:finish:)]) {
                        [delegate layerDisplayCompletion:self finish:NO];
                    }
                }else{
                    self.contents = (__bridge id)(image.CGImage);
                    if ([delegate respondsToSelector:@selector(layerDisplayCompletion:finish:)]) {
                        [delegate layerDisplayCompletion:self finish:YES];
                    }
                }
            });
            
        });
        
    }
    
}

- (void)_cancelAsyncDisplay {
    [_sentinel increase];
}

@end
