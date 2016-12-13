//
//  PFTextTagRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/12/12.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextTagRun.h"

@implementation PFTextTagRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    NSString *regulaStr = @"#[^#\\s]+?#";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    
    for (NSTextCheckingResult *match in mathes) {
        NSString *matchString = [string substringWithRange:match.range];
        if (runArray) {
            
            PFTextTagRun *run = [PFTextTagRun new];
            run.text = matchString;
            run.range = match.range;
            run.textColor = self.textColor;
            run.font = self.font;
            [runArray addObject:run];
        }
    }
    
    
}

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
    [attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:self.textColor?:(id)[UIColor orangeColor] range:self.range];
    [attributedString addAttribute:NSFontAttributeName value:self.font?:[UIFont systemFontOfSize:12] range:self.range];
}



@end
