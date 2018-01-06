//
//  PFTextLocalImageRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextLocalImageRun.h"
#import "UIImage+PFGIF.h"

@implementation PFTextLocalImageRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    NSString *regulaStr = @"`[^`\\s]+?`";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *match in mathes) {
        NSString *matchString = [string substringWithRange:match.range];
        NSString *imageName = matchString;
        if (matchString.length>2) {
            imageName = [imageName substringToIndex:imageName.length-1];
            imageName = [imageName substringFromIndex:1];
        }
        
        if (runArray) {
            UIImage *image = [UIImage pf_animatedGIFNamed:imageName];
            if (!image) {
                continue;
            }
            NSAssert(image, @"本地图片不存在");
            PFTextLocalImageRun *run = [[PFTextLocalImageRun alloc]init];
            run.image = image;
            run.imageName = imageName;
            run.range = match.range;
            run.defaultSize = self.defaultSize;
            run.offsetX = self.offsetX;
            run.offsetY = self.offsetY;
            [runArray addObject:run];
        }
        
    }
    
    
}

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
}

- (void)drawRunWithRect:(CGRect)rect context:(CGContextRef)context textView:(UIView *)textView
{
    if (_image) {
        if (_image._isGIF)
        {
            //由于coretext进行过坐标转化,这里添加layer的话rect需要变换下
            CGRect drawRect = CGRectMake(rect.origin.x, CGRectGetHeight(textView.bounds)-rect.origin.y-rect.size.height, rect.size.width, rect.size.height);
            CALayer *layer = [[CALayer alloc] init];
            layer.frame = drawRect;
            [textView.layer addSublayer:layer];
            NSMutableArray *source = [NSMutableArray array];
            for (int i = 0; i < _image.images.count; i++) {
                UIImage *image = _image.images[i];
                //用CFBridgingRelease会有内存错误crash
                [source addObject:CFRetain(image.CGImage)];
            }
            CAKeyframeAnimation *gifAni = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            [gifAni setValues:source];
            gifAni.duration = _image.duration;
            [gifAni setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
            gifAni.repeatCount = MAXFLOAT;
            gifAni.fillMode = kCAFillModeBoth;
            gifAni.delegate = self;
            gifAni.removedOnCompletion = NO;
            [layer addAnimation:gifAni forKey:@"gifAni"];
            for (int i = 0; i < source.count; i++) {
                CFTypeRef image = (__bridge CFTypeRef)source[i];
                CFRelease(image);
            }
        }
        else
        {
            CGContextDrawImage(context, rect, _image.CGImage);
        }
    }
}

#pragma mark - run call back

- (void)runDeallocCallback
{
}

- (CGFloat)runGetAscentCallback
{
    CGFloat ascent = 0;
    if (self.image) {
        
        if (CGSizeEqualToSize(self.defaultSize, PFTextViewRunDelegateMaximumSize)) {
            
            ascent = self.image.size.height;
        }else{
            
            ascent = self.defaultSize.height;
        }
        
    }
    
    return ascent;
}

- (CGFloat)runGetDescentCallback
{
    CGFloat descent = 0;
    
    return descent;
    
}

- (CGFloat)runGetWidthCallback
{
    CGFloat width = 0;
    if (self.image) {
        
        if (CGSizeEqualToSize(self.defaultSize, PFTextViewRunDelegateMaximumSize)) {
            
            width = self.image.size.width;
        }
        else{
            
            width = self.defaultSize.width;
        }
        
    }
    
    return width;
}


@end
