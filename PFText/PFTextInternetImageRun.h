//
//  PFTextInternetImageRun.h
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextRunDelegateRun.h"

@interface PFTextInternetImageRun : PFTextRunDelegateRun

/**
 默认尺寸, 如果设置为 PFTextViewRunDelegateMaximumSize 则为图片自身大小. defaultSize可以用于设置设置emoji
 如要修改 , 可以这configRun:,  parseText:textRunsArray:中进行修改
 */
@property (nonatomic, assign) CGSize defaultSize;

@property (nonatomic, strong) UIImage *placeholderImage;

@property (nonatomic, strong) NSURL *imageUrl;

@property (nonatomic, strong) UIImage *internetImage;


@end
