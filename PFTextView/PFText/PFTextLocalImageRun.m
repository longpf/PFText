//
//  PFTextLocalImageRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextLocalImageRun.h"

@implementation PFTextLocalImageRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    NSString *regulaStr = @"#[^#\\s]+?#";
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
            UIImage *image = [UIImage imageNamed:imageName];
            NSAssert(image, @"本地图片不存在");
            PFTextLocalImageRun *run = [[PFTextLocalImageRun alloc]init];
            run.image = image;
            run.imageName = imageName;
            run.range = match.range;
            run.defaultSize = self.defaultSize;
            [runArray addObject:run];
        }
        
    }
    
    
}

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
}

- (void)drawRunWithRect:(CGRect)rect
{
    if (_image) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, rect, _image.CGImage);
        UIGraphicsEndImageContext();
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
