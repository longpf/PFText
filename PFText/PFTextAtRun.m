//
//  PFTextAtRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextAtRun.h"

@implementation PFTextAtRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    
    NSError *error;
    
    NSString *regulaStr = @"@([^\\#|\\s\\@:：|\\p{P}]+)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *match in mathes) {
        
        NSString *matchString = [string substringWithRange:match.range];
        
        if (runArray) {
            
            PFTextAtRun *atRun = [[PFTextAtRun alloc]init];
            atRun.range = match.range;
            atRun.text = matchString;
            atRun.font = self.font;
            atRun.textColor = self.textColor;
            atRun.offsetX = self.offsetX;
            atRun.offsetY = self.offsetY;
            [runArray addObject:atRun];
            
        }
        
    }
}


/**
 配置@的run,在这可以设置@的字体和颜色
 
 @param attributedString 需要配置的字符串
 */
- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
    

    [attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:self.textColor?:(id)[UIColor colorWithRed:255.0/255 green:124.0/255 blue:78.0/255 alpha:1] range:self.range];
    [attributedString addAttribute:NSFontAttributeName value:self.font?:[UIFont systemFontOfSize:12] range:self.range];
}


@end
