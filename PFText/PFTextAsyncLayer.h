//
//  PFTextAsyncLayer.h
//  PFTextView
//
//  Created by 龙鹏飞 on 2017/8/10.
//  Copyright © 2017年 https://github.com/LongPF/PFText. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@class PFTextAsyncLayer;

@protocol PFTextAsyncLayerDelegate <NSObject>

@required
- (void)layerDispaly:(CGContextRef)context size:(CGSize)size isSuspended:(BOOL(^)(void))isSuspended;
@optional
- (void)layerWillDisplay:(PFTextAsyncLayer *)layer;
- (void)layerDisplayCompletion:(PFTextAsyncLayer *)layer finish:(BOOL)finish;

@end

@interface PFTextAsyncLayer : CALayer

@property (nonatomic, assign) BOOL displaysAsynchronously;
@property (nonatomic, weak) id<PFTextAsyncLayerDelegate> asyncLayerDelegate;

@end
