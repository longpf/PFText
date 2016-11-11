//
//  PFTextRunDelegateRun.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextRunDelegateRun.h"

const CGSize PFTextViewRunDelegateMaximumSize = (CGSize){0x100000,0x100000};

@interface PFTextRunDelegateRun ()

@property (nonatomic) CTRunDelegateRef runDelegate;

@end

@implementation PFTextRunDelegateRun

#pragma mark - life cycle

- (instancetype)init
{
    if (self = [super init]) {
        
        [self initialize];
        
    }
    
    return self;
}

- (void)initialize
{
    
    self.drawSelf = YES;
    
    CTRunDelegateCallbacks callbacks;
    callbacks.version = kCTRunDelegateVersion1;
    callbacks.dealloc = runDelegateDeallocCallback;
    callbacks.getAscent = runDelegateGetAscentCallback;
    callbacks.getDescent = runDelegateGetDescentCallback;
    callbacks.getWidth = runDelegateGetWidthCallback;
    
    self.runDelegate = CTRunDelegateCreate(&callbacks, (__bridge_retained void *)self);
    
}


- (void)dealloc
{
    if (_runDelegate) {
        CFRelease(_runDelegate);
    }
}

#pragma mark - interface methods

- (void)configRun:(NSMutableAttributedString *)attributedString
{
    [super configRun:attributedString];
    
    [attributedString addAttribute:(id)kCTRunDelegateAttributeName value:(__bridge id)self.runDelegate range:self.range];
    [attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)[UIColor clearColor].CGColor range:self.range];
}

#pragma mark - run call back

- (void)runDeallocCallback
{
    
}

- (CGFloat)runGetAscentCallback
{
    
    return 0;
}

- (CGFloat)runGetDescentCallback
{
    return 0;
}

- (CGFloat)runGetWidthCallback
{
    return 0;
}


#pragma mark - runDelegate call back

void runDelegateDeallocCallback(void *refCon)
{
    PFTextRunDelegateRun *run = (__bridge PFTextRunDelegateRun *)refCon;
    [run runDeallocCallback];
}

CGFloat runDelegateGetAscentCallback(void *refCon)
{
    PFTextRunDelegateRun *run = (__bridge PFTextRunDelegateRun *)refCon;
    return [run runGetAscentCallback];
}

CGFloat runDelegateGetDescentCallback(void *refCon)
{
    PFTextRunDelegateRun *run = (__bridge PFTextRunDelegateRun *)refCon;
    return [run runGetDescentCallback];
}

CGFloat runDelegateGetWidthCallback(void *refCon)
{
    PFTextRunDelegateRun *run = (__bridge PFTextRunDelegateRun *)refCon;
    return [run runGetWidthCallback]/run.range.length;
}


@end
