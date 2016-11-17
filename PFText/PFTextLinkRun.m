//
//  PFTextLinkRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextLinkRun.h"

@implementation PFTextLinkRun

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    NSError *error;
    
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *mathes = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];

    for (NSTextCheckingResult *match in mathes) {
        
        NSString *matchString = [string substringWithRange:match.range];
        
        if (runArray) {
            
            PFTextLinkRun *atRun = [[PFTextLinkRun alloc]init];
            atRun.range = match.range;
            atRun.text = matchString;
            atRun.font = self.font;
            atRun.textColor = self.textColor;
            [runArray addObject:atRun];
        }
    }
    
}

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
    [attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:self.textColor?:[UIColor blueColor] range:self.range];
    [attributedString addAttribute:NSFontAttributeName value:self.font?:[UIFont systemFontOfSize:12] range:self.range];
}


@end
