//
//  PFTextRunDelegateRun.h
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextRun.h"

@interface PFTextRunDelegateRun : PFTextRun

//子类需要重写着4个方法
- (void)runDeallocCallback;
- (CGFloat)runGetAscentCallback;
- (CGFloat)runGetDescentCallback;
- (CGFloat)runGetWidthCallback;

@end

FOUNDATION_EXTERN const CGSize PFTextViewRunDelegateMaximumSize;

