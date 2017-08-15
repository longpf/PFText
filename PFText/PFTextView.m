//
//  PFTextView.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "PFTextView.h"
#import "PFTextAsyncLayer.h"

static unichar const replacementChar = 0xFFFC;


@interface PFTextView ()<PFTextAsyncLayerDelegate>

@property (nonatomic, strong) NSMutableArray *runs; //需要特殊处理的run的数组
@property (nonatomic, strong) NSMutableDictionary *runRectDictionary; //储存每个PFTextRun的CGRect
@property (nonatomic, strong) NSMutableAttributedString *attributeString;
@property (nonatomic, strong) NSDictionary *universalAttributes; //加在整个text上的属性
@property (nonatomic, assign) BOOL needHeightToFit;
@property (nonatomic, assign) PFTextRun *longPressRun;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, assign) BOOL __hasIssue;

@end

@implementation PFTextView

#pragma mark - life cycle

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self initialize];
        self.frame = frame;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    self.runs = [NSMutableArray array];
    self.runRectDictionary = [NSMutableDictionary dictionary];
    
    _lineSpacing = 2;
    _font = [UIFont systemFontOfSize:12];
    _textColor = [UIColor blackColor];
    _text = @"";
    _firstLineHeadIndent = 0;
    _paragraphHeadIndent = 0;
    _paragraphTailIndent = 0;
    _needHeightToFit = NO;
    PFTextAsyncLayer *layer = (PFTextAsyncLayer *)self.layer;
    layer.asyncLayerDelegate = self;
    layer.displaysAsynchronously = NO;
    //layer.drawsAsynchronously = YES;
    layer.contentsScale = [UIScreen mainScreen].scale;
    self.contentMode = UIViewContentModeRedraw;

}

- (void)dealloc
{
    NSLog(@"[PFTextView dealloc]");
}

+ (Class)layerClass
{
    return [PFTextAsyncLayer class];
}

#pragma mark - PFTextAsyncLayerDelegate

- (void)layerWillDisplay:(PFTextAsyncLayer *)layer
{
    
}

- (void)layerDispaly:(CGContextRef)context size:(CGSize)size isSuspended:(BOOL (^)(void))isSuspended
{
    if (isSuspended()) {
        return;
    }
    
    [self _draw:context];
}

- (void)layerDisplayCompletion:(PFTextAsyncLayer *)layer finish:(BOOL)finish
{
    
}

#pragma mark - draw

//如果实现这个方法则则不回绘制背景色 原因??
//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//}

- (void)_draw:(CGContextRef)context
{
    [self.runRectDictionary removeAllObjects];
    
    //解析文本 找出需要特殊处理的run
    if (self.runs.count == 0) {
        [self parseText:self.text runs:self.runs];
        //根据run的location从高到底排序 方便之后的空白符替换
        [self.runs sortUsingComparator:^NSComparisonResult(PFTextRun *obj1, PFTextRun *obj2) {
            if (obj1.range.location > obj2.range.location) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }];
    }
    
    
    //配置 文本
    [self createAttributedString];
    
    if (!self.attributeString) {
        return;
    }
    
    //把特殊run的属性 写到 attString 里面
    __weak typeof(self) wself = self;
    for (int i = 0 ; i < self.runs.count ;i++) {
        
        PFTextRun *run = self.runs[i];
        
        [run configRun:self.attributeString];
        
        if (run.isDrawSelf) {
            //对需要自己绘制的进行空白符替换占位
            NSString *replacementString = [NSString stringWithCharacters:&replacementChar length:1];
            [self.attributeString replaceCharactersInRange:run.range withString:replacementString];
        }
        
        
        run.needDisplay = ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (wself.needHeightToFit) {
                    [wself heightToFit];
                }
//                [wself setNeedsDisplay];
                [wself.layer setNeedsDisplay];
            });
        };
    }
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
    //修正坐标系
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    transform = CGAffineTransformScale(transform, 1, -1);
    CGContextConcatCTM(context, transform);
    
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL, self.bounds);
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributeString);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, 0), pathRef, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), lineOrigins);
    
    //绘制
    long lastLineIndex = [self drawLineByLine:lines lineOrigins:lineOrigins context:context];
    if (lastLineIndex == -1) {
        CFRelease(pathRef);
        CFRelease(frameRef);
        CFRelease(framesetterRef);
        return;
    }
    
    //将每一个的PFTextRun的rect储存起来
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        
        if (lastLineIndex > 0 &&  i >= lastLineIndex) {
            break;
        }
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin = lineOrigins[i];
        
        [self storeRunRectAndDrawRunSelf:context lineRef:lineRef lineOrigin:lineOrigin];
        
    }
    
    
    CFRelease(pathRef);
    CFRelease(frameRef);
    CFRelease(framesetterRef);
//    UIGraphicsEndImageContext();
}

//- (void)drawRect:(CGRect)rect
//{
//    [super drawRect:rect];
//}

/**
 绘制除了最后一行的行元素  一行一行的绘制,  方便处理 lineBreakMode,numberOfLines, 返回最后一行的角标
 
 @param lines       每行的数组
 @param lineOrigins 每行的起点
 @param context     绘制上下文
 
 @return 返回最后一行的角标,-1表示有错误
 */
- (long)drawLineByLine:(CFArrayRef)lines lineOrigins:(CGPoint *)lineOrigins context:(CGContextRef)context;
{

    
    unsigned long lineCount = CFArrayGetCount(lines);
    
    if (lineCount < 1) return 0;
    
    for (NSInteger i = 0; i < lineCount - 1 && (_numberOfLines==0 || i < _numberOfLines); i++) {
        
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin = lineOrigins[i];
        CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
        CTLineDraw(lineRef, context);
    }
    
    NSInteger lastIndex = (_numberOfLines==0 || _numberOfLines > lineCount) ? lineCount-1 : _numberOfLines-1;
    CGPoint lastLineOrigin = lineOrigins[lastIndex];
    CGContextSetTextPosition(context, lastLineOrigin.x, lastLineOrigin.y);
    
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, lastIndex);
    
    if (!self.attributeString) {
        return -1;
    }
    
    if ((self.lineBreakMode != NSLineBreakByTruncatingHead && self.lineBreakMode != NSLineBreakByTruncatingTail && self.lineBreakMode != NSLineBreakByTruncatingMiddle) ||
        (CTLineGetStringRange(lastLine).location+CTLineGetStringRange(lastLine).length == self.attributeString.string.length))
    {
        CTLineDraw(lastLine, context);
        [self storeRunRectAndDrawRunSelf:context lineRef:lastLine lineOrigin:lastLineOrigin];
    }else{
        
        CTLineBreakMode lineBreak = (CTLineBreakMode)self.lineBreakMode;
        CTParagraphStyleSetting lineBreakStyle;
        lineBreakStyle.spec = kCTParagraphStyleSpecifierLineBreakMode;
        lineBreakStyle.value = &lineBreak;
        lineBreakStyle.valueSize = sizeof(CTLineBreakMode);
        
        CTParagraphStyleSetting firstLineHeadIndent;
        firstLineHeadIndent.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
        firstLineHeadIndent.value = &_firstLineHeadIndent;
        firstLineHeadIndent.valueSize = sizeof(CGFloat);
        
        CTParagraphStyleSetting headIndent;
        headIndent.spec = kCTParagraphStyleSpecifierHeadIndent;
        headIndent.value = &_paragraphHeadIndent;
        headIndent.valueSize = sizeof(CGFloat);
        
        CTParagraphStyleSetting tailIndent;
        tailIndent.spec = kCTParagraphStyleSpecifierTailIndent;
        tailIndent.value = &_paragraphTailIndent;
        tailIndent.valueSize = sizeof(CGFloat);
        
        CTParagraphStyleSetting settings[] = {lineBreakStyle,firstLineHeadIndent,headIndent,tailIndent};
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 4);
        
        CFAttributedStringSetAttribute((CFMutableAttributedStringRef)self.attributeString, CFRangeMake(CTLineGetStringRange(lastLine).location, CTLineGetStringRange(lastLine).length), kCTParagraphStyleAttributeName, paragraphStyle);
        
        //省略号
        static NSString* const kEllipsesCharacter = @"\u2026";
        NSAttributedString *ellipsesChar = [[NSAttributedString alloc] initWithString:kEllipsesCharacter attributes:self.universalAttributes];
        
        NSInteger lastLineLocation = CTLineGetStringRange(lastLine).location;
        NSInteger lastLineLength = CTLineGetStringRange(lastLine).length;;
        
        //最后一行的字符串
        NSMutableAttributedString *subAttributedString = [[self.attributeString attributedSubstringFromRange:NSMakeRange(lastLineLocation, lastLineLength)] mutableCopy];
        
        NSInteger insertCharacterLocation = lastLineLength - 1;
        
        if (self.lineBreakMode == NSLineBreakByTruncatingHead) {
            insertCharacterLocation = 0;
        }
        else if (self.lineBreakMode == NSLineBreakByTruncatingMiddle){
            CFArrayRef lastLineRuns = CTLineGetGlyphRuns(lastLine);
            NSInteger lastLineRunCount = CFArrayGetCount(lastLineRuns) ;
            CTRunRef lastLineMiddleRun = CFArrayGetValueAtIndex(lastLineRuns, (unsigned long)lastLineRunCount/2);
            CFRange lastLineMiddleRunRange = CTRunGetStringRange(lastLineMiddleRun);
            insertCharacterLocation = (lastLineMiddleRunRange.location-lastLineLocation) + lastLineMiddleRunRange.length;
        }
        
        [subAttributedString deleteCharactersInRange:NSMakeRange(lastLineLength-1, 1)];
        [subAttributedString insertAttributedString:ellipsesChar atIndex:insertCharacterLocation];
        
        CFAttributedStringSetAttribute((CFMutableAttributedStringRef)subAttributedString, CFRangeMake(0, subAttributedString.length), kCTParagraphStyleAttributeName, paragraphStyle);
        
        CTLineRef lastLineSub = CTLineCreateWithAttributedString((CFMutableAttributedStringRef)subAttributedString);
        CGPoint lastLineOrigin = lineOrigins[lastIndex];
        CGContextSetTextPosition(context, lastLineOrigin.x, lastLineOrigin.y);
        
        CTLineDraw(lastLineSub, context);
        
        [self storeRunRectAndDrawRunSelf:context lineRef:lastLineSub lineOrigin:lastLineOrigin];
        
        CFRelease(lastLineSub);
        CFRelease(paragraphStyle);
    }
    
    return lastIndex;
    
}

- (void)storeRunRectAndDrawRunSelf:(CGContextRef)context lineRef:(CTLineRef)lineRef lineOrigin:(CGPoint)lineOrigin
{
    CGFloat lineAscent,lineDescent,lineLeading;
    CTLineGetTypographicBounds(lineRef, &lineAscent, &lineDescent, &lineLeading);
    CFArrayRef runs = CTLineGetGlyphRuns(lineRef);
    
    for (int j = 0; j < CFArrayGetCount(runs); j++) {
        
        CTRunRef runRef = CFArrayGetValueAtIndex(runs, j);
        CGFloat runAscent, runDescent;
        CGRect runRect;
        
        runRect = CGRectMake(lineOrigin.x+CTLineGetOffsetForStringIndex(lineRef,
                                                                        CTRunGetStringRange(runRef).location, NULL),
                             lineOrigin.y,
                             CTRunGetTypographicBounds(runRef, CFRangeMake(0, 0), &runAscent,&runDescent, NULL),
                             runAscent+runDescent);
        
        NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(runRef);
        PFTextRun *richTextRun = [attributes objectForKey:kPFTextAttributeName];
        
        if (richTextRun && richTextRun.isDrawSelf) {
            
            [richTextRun drawRunWithRect:runRect context:context];
            [self.runRectDictionary setObject:richTextRun forKey:[NSValue valueWithCGRect:runRect]];
            
        }else if (richTextRun){
            
            [self.runRectDictionary setObject:richTextRun forKey:[NSValue valueWithCGRect:runRect]];
            
        }
        
    }
}

#pragma mark - createAttributedString

- (void)createAttributedString
{
    self.attributeString = [[NSMutableAttributedString alloc] initWithString:self.text attributes:@{}];
    
    if (!self.attributeString) {
        return;
    }
    
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)[self.font fontName], [self.font pointSize], &CGAffineTransformIdentity);
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)self.attributeString, CFRangeMake(0, self.attributeString.string.length), kCTFontAttributeName, fontRef);
    
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)self.attributeString, CFRangeMake(0, self.attributeString.string.length), kCTForegroundColorAttributeName, self.textColor.CGColor);
    
    
    static NSDictionary *alignments;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        alignments = @{
                       @(NSTextAlignmentCenter):@(kCTTextAlignmentCenter),
                       @(NSTextAlignmentRight):@(kCTTextAlignmentRight)
                       };
    });
    CTTextAlignment alignment = [alignments[@(self.textAlignment)] unsignedCharValue]?:kCTTextAlignmentLeft;
    CTParagraphStyleSetting alignmentStyle;
    alignmentStyle.spec = kCTParagraphStyleSpecifierAlignment;
    alignmentStyle.value = &alignment;
    alignmentStyle.valueSize = sizeof(alignment);
    
    CTParagraphStyleSetting lineSpaceStyle;
    CGFloat lineSpacing = self.lineSpacing;
    lineSpaceStyle.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    lineSpaceStyle.value = &lineSpacing;
    lineSpaceStyle.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting firstLineHeadIndent;
    CGFloat firstLineHeadIndentValue = self.firstLineHeadIndent;
    firstLineHeadIndent.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
    firstLineHeadIndent.value = &firstLineHeadIndentValue;
    firstLineHeadIndent.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting headIndent;
    CGFloat headIndentValue = self.paragraphHeadIndent;
    headIndent.spec = kCTParagraphStyleSpecifierHeadIndent;
    headIndent.value = &headIndentValue;
    headIndent.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting tailIndent;
    CGFloat tailIndentValue = self.paragraphTailIndent;
    tailIndent.spec = kCTParagraphStyleSpecifierTailIndent;
    tailIndent.value = &tailIndentValue;
    tailIndent.valueSize = sizeof(CGFloat);
    
    CTParagraphStyleSetting settings[] = {alignmentStyle,lineSpaceStyle,firstLineHeadIndent,headIndent,tailIndent};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, 5);
    
    // 如果lineBreakMode设置... 就只显示一行
    if (self.lineBreakMode != NSLineBreakByTruncatingHead && self.lineBreakMode != NSLineBreakByTruncatingTail && self.lineBreakMode != NSLineBreakByTruncatingMiddle) {
        CTLineBreakMode lineBreak = (CTLineBreakMode)self.lineBreakMode;
        CTParagraphStyleSetting lineBreakStyle;
        lineBreakStyle.spec = kCTParagraphStyleSpecifierLineBreakMode;
        lineBreakStyle.value = &lineBreak;
        lineBreakStyle.valueSize = sizeof(CTLineBreakMode);
        
        CTParagraphStyleSetting settings[] = {lineBreakStyle,alignmentStyle,lineSpaceStyle,firstLineHeadIndent,headIndent,tailIndent};
        paragraphStyle = CTParagraphStyleCreate(settings, 6);
    }
    
    
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)self.attributeString, CFRangeMake(0, self.attributeString.string.length), kCTParagraphStyleAttributeName, paragraphStyle);
    
    CFRelease(paragraphStyle);
    
    if (self.attributeString.string.length > 0) {
        self.universalAttributes = [self.attributeString attributesAtIndex:0 effectiveRange:NULL];
    }
}

#pragma mark - get special runs

- (void)parseText:(NSString *)string runs:(NSMutableArray *)runs
{
    for (PFTextRun *settingRun in self.settingRuns) {
        
        if (!settingRun.textColor) {
            settingRun.textColor = self.textColor;
        }
        if (!settingRun.font) {
            settingRun.font = self.font;
        }
        [settingRun parseText:string textRunsArray:runs];
        
    }
}




#pragma mark - fit

- (CGFloat)heightThatFit:(CGFloat)width
{
    if (width == 0.0) {
        width = self.bounds.size.width;
    }
    
    if (self.runs.count == 0) {
        [self parseText:self.text runs:self.runs];
        [self.runs sortUsingComparator:^NSComparisonResult(PFTextRun *obj1, PFTextRun *obj2) {
            if (obj1.range.location > obj2.range.location) {
                return NSOrderedAscending;
            }else{
                return NSOrderedDescending;
            }
        }];
    }
    
    [self createAttributedString];
    
    for (int i = 0; i < self.runs.count; i++) {
        PFTextRun *run = self.runs[i];
        [run configRun:self.attributeString];
        if (run.isDrawSelf) {
            //对需要自己绘制的进行空白符替换占位
            NSString *replacementString = [NSString stringWithCharacters:&replacementChar length:1];
            [self.attributeString replaceCharactersInRange:run.range withString:replacementString];
        }
    }
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL, CGRectMake(0, 0, width, MAXFLOAT));
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributeString);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, 0), pathRef, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frameRef);
    NSInteger lineCount = CFArrayGetCount(lines);
    
    if (lineCount == 0) return 0;
    
    NSInteger lastLineIndex = (_numberOfLines==0 || _numberOfLines > lineCount) ? lineCount - 1: _numberOfLines - 1;
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, lastLineIndex);
    CFRange fitRange = CFRangeMake(0, CTLineGetStringRange(lastLine).location+CTLineGetStringRange(lastLine).length);
    CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetterRef, fitRange, NULL, CGSizeMake(width, MAXFLOAT), &fitRange);
    
    CFRelease(pathRef);
    CFRelease(framesetterRef);
    CFRelease(frameRef);
    
    return fitSize.height;
}


- (void)heightToFit
{
    CGFloat fitHeight = [self heightThatFit:self.bounds.size.width];
    CGRect fitRect = self.frame;
    fitRect.size.height = fitHeight;
    self.frame = fitRect;
    self.needHeightToFit = YES;
}

#pragma mark - response methods

- (void)longPressHandler:(UILongPressGestureRecognizer *)longPress
{
    if (!self.enableMenuController) {
        return;
    }
    
    if (self.__hasIssue) {
#ifdef DEBUG
        NSAssert(NO, @"注意： 请确认PFTextView所在的UIViewController没有与inputView同名的属性，有的话请换个属性名字，否则可能出错");
#endif
        return;
    }
    
    @try {
        
        [self becomeFirstResponder];
        
    } @catch (NSException *exception) {
        
        self.__hasIssue = YES;
        
    } @finally {
        
    }
    
    if (self.__hasIssue) {
#ifdef DEBUG
        NSAssert(NO, @"注意： 请确认PFTextView所在的UIViewController没有与inputView同名的属性，有的话请换个属性名字，否则可能出错");
#endif
        return;
    }

    __block PFTextRun *targetRun = nil;
    __block CGRect targetRect = CGRectZero;
    CGPoint runLocation = [longPress locationInView:self];
    runLocation = CGPointMake(runLocation.x, self.frame.size.height-runLocation.y);
    
    [self.runRectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, PFTextRun *obj, BOOL *stop){
        
        CGRect rect = [((NSValue *)key) CGRectValue];
        if(CGRectContainsPoint(rect, runLocation))
        {
            targetRun = obj;
            targetRect = rect;
        }
        
    }];

    if (targetRun == self.longPressRun && [UIMenuController sharedMenuController].isMenuVisible) {
        return;
    }
    
    UIMenuItem *copyRunText, *copyFullText, *copyRunImage;
    NSMutableArray *items = [NSMutableArray array];
    if (targetRun) {
        self.longPressRun = targetRun;
        if (targetRun.pasteText) {
            copyRunText = [[UIMenuItem alloc]initWithTitle:@"复制选中文本" action:@selector(copyRunText:)];
        }
        if (targetRun.pasteImage) {
            copyRunImage = [[UIMenuItem alloc]initWithTitle:@"复制选中图片" action:@selector(copyRunImage:)];
        }
    }
    copyFullText = [[UIMenuItem alloc]initWithTitle:@"复制全部文本" action:@selector(copyFullText:)];
    
    
    if (copyRunText) [items addObject:copyRunText];
    if (copyRunImage) [items addObject:copyRunImage];
    if (copyFullText) [items addObject:copyFullText];
    
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:items];
    
    if (!CGRectEqualToRect(targetRect, CGRectZero)) {
        
        targetRect.origin.y = self.frame.size.height-targetRect.origin.y;
        
        [menu setTargetRect:targetRect inView:self];
    }else{
        [menu setTargetRect:self.bounds inView:self];
    }
    
    [menu setMenuVisible:YES animated:YES];

}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyRunText:) || action == @selector(copyFullText:) || action == @selector(copyRunImage:)) {
        return YES;
    }
    return NO;
}


#pragma mark - menu

- (void)copyRunText:(id)sender
{
    if (self.longPressRun) {
        [UIPasteboard generalPasteboard].string = self.longPressRun.pasteText;
        self.longPressRun = nil;
    }
    
}

- (void)copyFullText:(id)sender
{
    if (self.text && [self.text isKindOfClass:[NSString class]] && self.text.length) {
        [UIPasteboard generalPasteboard].string = self.text;
        self.longPressRun = nil;
    }

}

- (void)copyRunImage:(id)sender
{
    if (self.longPressRun) {
        [UIPasteboard generalPasteboard].image = self.longPressRun.pasteImage;;
        self.longPressRun = nil;
    }
}


#pragma mark - touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    CGPoint location = [(UITouch *)[touches anyObject] locationInView:self];
    CGPoint runLocation = CGPointMake(location.x, self.frame.size.height - location.y);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:touchBeginRun:)])
    {
        __weak typeof(self) wself = self;
        
        [self.runRectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            
            CGRect rect = [((NSValue *)key) CGRectValue];
            if(CGRectContainsPoint(rect, runLocation))
            {
                [wself.delegate textView:wself touchBeginRun:obj];
            }
        }];
    }
    

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    self.longPressRun = nil;
    
    [super touchesEnded:touches withEvent:event];
    
    CGPoint location = [(UITouch *)[touches anyObject] locationInView:self];
    CGPoint runLocation = CGPointMake(location.x, self.frame.size.height - location.y);
    
    __block BOOL hasEventRun = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView:touchEndRun:)])
    {
        __weak typeof(self) wself = self;
        
        [self.runRectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            
            CGRect rect = [((NSValue *)key) CGRectValue];
            if(CGRectContainsPoint(rect, runLocation))
            {
                hasEventRun = YES;
                [wself.delegate textView:wself touchEndRun:obj];
            }
        }];
    }
    
    if (!hasEventRun) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(textView:touchEnded:)]) {
            [self.delegate textView:self touchEnded:event];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    CGPoint location = [(UITouch *)[touches anyObject] locationInView:self];
    CGPoint runLocation = CGPointMake(location.x, self.frame.size.height - location.y);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textView: touchCanceledRun:)])
    {
        __weak typeof(self) wself = self;
        
        [self.runRectDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            
            CGRect rect = [((NSValue *)key) CGRectValue];
            if(CGRectContainsPoint(rect, runLocation))
            {
                [wself.delegate textView:wself touchCanceledRun:obj];
            }
        }];
    }
}
#pragma mark - getters / setters

- (void)setSettingRuns:(NSArray<PFTextRun *> *)settingRuns
{
    if (_settingRuns != settingRuns) {
        _settingRuns = settingRuns;
        [self.runs removeAllObjects];
        [self.layer setNeedsDisplay];
    }
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        [_runRectDictionary removeAllObjects];
        [self.layer setNeedsDisplay];
    }
}

- (void)setText:(NSString *)text
{
    if (_text != text) {
        _text = text;
        self.attributeString = nil;
        [self.runs removeAllObjects];
        [self.layer setNeedsDisplay];
    }
}

- (void)setFont:(UIFont *)font
{
    if (_font != font) {
        _font = font;
        [self.layer setNeedsDisplay];
    }
    
}

- (void)setTextColor:(UIColor *)textColor
{
    if (textColor != _textColor) {
        _textColor = textColor;
        [self.layer setNeedsDisplay];
    }
}

- (void)setParagraphHeadIndent:(CGFloat)paragraphHeadIndent
{
    if (_paragraphHeadIndent != paragraphHeadIndent) {
        _paragraphHeadIndent = paragraphHeadIndent;
        [self.layer setNeedsDisplay];
    }
}

- (void)setParagraphTailIndent:(CGFloat)paragraphTailIndent
{
    if (_paragraphTailIndent != paragraphTailIndent) {
        _paragraphTailIndent = paragraphTailIndent;
        [self.layer setNeedsDisplay];
    }
}

- (void)setFirstLineHeadIndent:(CGFloat)firstLineHeadIndent
{
    if (_firstLineHeadIndent != firstLineHeadIndent) {
        _firstLineHeadIndent = firstLineHeadIndent;
        [self.layer setNeedsDisplay];
    }
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if (_numberOfLines != numberOfLines) {
        _numberOfLines = numberOfLines;
        [self.layer setNeedsDisplay];
    }
}

- (void)setDisplaysAsynchronously:(BOOL)displaysAsynchronously
{
    if (_displaysAsynchronously != displaysAsynchronously) {
        _displaysAsynchronously = displaysAsynchronously;
        PFTextAsyncLayer *layer = (PFTextAsyncLayer *)self.layer;
        layer.displaysAsynchronously = displaysAsynchronously;
        [self.layer setNeedsDisplay];
    }
}

- (void)setEnableMenuController:(BOOL)enableMenuController
{
    if (_enableMenuController != enableMenuController) {
        _enableMenuController = enableMenuController;
        if (enableMenuController) {
            if (![self.gestureRecognizers containsObject:self.longPress]) {
                [self addGestureRecognizer:self.longPress];
            }
        }else{
            if ([self.gestureRecognizers containsObject:self.longPress]) {
                [self removeGestureRecognizer:self.longPress];
            }
        }
    }
}

- (UILongPressGestureRecognizer *)longPress
{
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressHandler:)];
    }
    return _longPress;
}

- (NSMutableAttributedString *)attributeString
{
    if (!_attributeString) {
        _attributeString = [[NSMutableAttributedString alloc] initWithString:self.text?:@""];
    }
    return _attributeString;
}

@end
