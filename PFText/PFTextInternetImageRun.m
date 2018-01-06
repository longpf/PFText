//
//  PFTextInternetImageRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextInternetImageRun.h"
#import "PFTextDownloader.h"
#import "UIImage+PFGIF.h"

@implementation PFTextInternetImageRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    NSString *regulaStr = @"``[^``\\s]+?``";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *match in mathes) {
        NSString *matchString = [string substringWithRange:match.range];
        NSString *urlString = matchString;
        if (matchString.length>2) {
            urlString = [urlString substringToIndex:urlString.length-2];
            urlString = [urlString substringFromIndex:2];
        }
        
        if (runArray) {
            
            PFTextInternetImageRun *run = [PFTextInternetImageRun new];
            run.placeholderImage = self.placeholderImage;
            if (urlString) run.imageUrl = [NSURL URLWithString:urlString];
            run.range = match.range;
            run.defaultSize = self.defaultSize;
            run.offsetX = self.offsetX;
            run.offsetY = self.offsetY;
            [runArray addObject:run];
        }
        
    }
    
}

- (void)drawRunWithRect:(CGRect)rect context:(CGContextRef)context textView:(UIView *)textView
{
    if (_internetImage) {
        if (_internetImage._isGIF)
        {
            //由于coretext进行过坐标转化,这里添加layer的话rect需要变换下
            CGRect drawRect = CGRectMake(rect.origin.x, CGRectGetHeight(textView.bounds)-rect.origin.y-rect.size.height, rect.size.width, rect.size.height);
            CALayer *layer = [[CALayer alloc] init];
            layer.frame = drawRect;
            [textView.layer addSublayer:layer];
            NSMutableArray *source = [NSMutableArray array];
            for (int i = 0; i < _internetImage.images.count; i++) {
                UIImage *image = _internetImage.images[i];
                //用CFBridgingRelease会有内存错误crash
                [source addObject:CFRetain(image.CGImage)];
            }
            CAKeyframeAnimation *gifAni = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            [gifAni setValues:source];
            gifAni.duration = _internetImage.duration;
            [gifAni setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
            gifAni.repeatCount = MAXFLOAT;
            [layer addAnimation:gifAni forKey:@"gifAni"];
            for (int i = 0; i < source.count; i++) {
                CFTypeRef image = (__bridge CFTypeRef)source[i];
                CFRelease(image);
            }
        }
        else
        {
            CGContextDrawImage(context, rect, _internetImage.CGImage);
        }
        return;
    }
    
    if (_placeholderImage) {
        if (_placeholderImage._isGIF)
        {
            //由于coretext进行过坐标转化,这里添加layer的话rect需要变换下
            CGRect drawRect = CGRectMake(rect.origin.x, CGRectGetHeight(textView.bounds)-rect.origin.y-rect.size.height, rect.size.width, rect.size.height);
            CALayer *layer = [[CALayer alloc] init];
            layer.frame = drawRect;
            [textView.layer addSublayer:layer];
            NSMutableArray *source = [NSMutableArray array];
            for (int i = 0; i < _placeholderImage.images.count; i++) {
                UIImage *image = _placeholderImage.images[i];
                //用CFBridgingRelease会有内存错误crash
                [source addObject:CFRetain(image.CGImage)];
            }
            CAKeyframeAnimation *gifAni = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            [gifAni setValues:source];
            gifAni.duration = _placeholderImage.duration;
            [gifAni setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
            gifAni.repeatCount = MAXFLOAT;
            [layer addAnimation:gifAni forKey:@"gifAni"];
            for (int i = 0; i < source.count; i++) {
                CFTypeRef image = (__bridge CFTypeRef)source[i];
                CFRelease(image);
            }
        }
        else
        {
            CGContextDrawImage(context, rect, _placeholderImage.CGImage);
        }
    }
    
    //下载网络图片
    if (self.imageUrl) {
        
        __weak typeof(self) wself = self;
        [PFDownloader pf_downloadTaskWithURL:self.imageUrl downloadProgress:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, double progress) {
            NSLog(@"图片下载进度:%f",progress);
        } completeHandler:^(NSURLSession *session, NSURLSessionTask *task, NSURL *filePath) {
            
            __strong typeof(wself) sself = wself;
            //            UIImage *image = [UIImage imageWithContentsOfFile:[filePath relativePath]];
//            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
            UIImage *image = [UIImage pf_animatedGIFWithData:[NSData dataWithContentsOfURL:filePath]];
            if (image) {
                sself.internetImage = image;
                if (sself.needDisplay) {
                    sself.needDisplay();
                }
            }
            
        } errorHandler:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
            NSLog(@"图片下载失败:%@",error);
        }];
        
    }
}


#pragma mark - run call back

- (void)runDeallocCallback
{
}

- (CGFloat)runGetAscentCallback
{
    CGFloat ascent = 0;
    UIImage *image = _internetImage?:_placeholderImage;
    if (image) {
        
        if (CGSizeEqualToSize(self.defaultSize, PFTextViewRunDelegateMaximumSize)) {
            
            ascent = image.size.height;
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
    UIImage *image = _internetImage?:_placeholderImage;
    if (image) {
        
        if (CGSizeEqualToSize(self.defaultSize, PFTextViewRunDelegateMaximumSize)) {
            
            width = image.size.width;
        }
        else{
            
            width = self.defaultSize.width;
        }
        
    }
    
    return width;
}



@end
