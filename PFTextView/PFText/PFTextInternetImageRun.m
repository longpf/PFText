//
//  PFTextInternetImageRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextInternetImageRun.h"
#import "PFTextDownloader.h"

@implementation PFTextInternetImageRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    NSString *regulaStr = @"&[^&\\s]+?&"; //#[^#\\s]+?#
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *match in mathes) {
        NSString *matchString = [string substringWithRange:match.range];
        NSString *urlString = matchString;
        if (matchString.length>2) {
            urlString = [urlString substringToIndex:urlString.length-1];
            urlString = [urlString substringFromIndex:1];
        }
        
        if (runArray) {
            
            PFTextInternetImageRun *run = [PFTextInternetImageRun new];
            run.placeholderImage = self.placeholderImage;
            if (urlString) run.imageUrl = [NSURL URLWithString:urlString];
            run.range = match.range;
            run.defaultSize = self.defaultSize;
            [runArray addObject:run];
        }
        
    }
    
}

- (void)drawRunWithRect:(CGRect)rect
{
    if (_internetImage) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, rect, _internetImage.CGImage);
        UIGraphicsEndImageContext();
        
        return;
    }
    
    if (_placeholderImage) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, rect, _placeholderImage.CGImage);
        UIGraphicsEndImageContext();
    }
    
    //下载网络图片
    if (self.imageUrl) {
        
        __weak typeof(self) wself = self;
        [PFDownloader pf_downloadTaskWithURL:self.imageUrl downloadProgress:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, double progress) {
            NSLog(@"图片下载进度:%f",progress);
        } completeHandler:^(NSURLSession *session, NSURLSessionTask *task, NSURL *filePath) {
            
            __strong typeof(wself) sself = wself;
            //            UIImage *image = [UIImage imageWithContentsOfFile:[filePath relativePath]];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];
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
    NSLog(@"runGetAscentCallback");
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
