//
//  PFTextRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextRun.h"

NSString * const kPFTextAttributeName = @"kPFTextAttributeName";


@implementation PFTextRun

- (instancetype)init
{
    if (self = [super init]) {
        
        self.weight = PFTextRunDefaultWeight;
        self.isResponseTouch = NO;
    }
    return self;
}

- (void)parseText:(NSString *)string textRunsArray:(NSMutableArray *)runArray
{
    
}

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    if (attributedString.string.length)
    {
        if ((self.range.location+self.range.length)<=attributedString.string.length)
        {
            [attributedString addAttribute:kPFTextAttributeName value:self range:self.range];
        }
    }
}

- (void)drawRunWithRect:(CGRect)rect context:(CGContextRef)context textView:(UIView *)textView
{
    
}

- (NSString *)pasteText
{
    if (!_pasteText) {
        return self.text;
    }
    return _pasteText;
}



@end
