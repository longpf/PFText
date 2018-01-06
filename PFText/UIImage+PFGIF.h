//
//  UIImage+PFGIF.h
//  PFTextView
//
//  Created by 龙鹏飞 on 2018/1/5.
//  Copyright © 2018年 https://github.com/LongPF/PFText. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 这个类借鉴SDWebImage
 */
@interface UIImage (PFGIF)

+ (UIImage *)pf_animatedGIFNamed:(NSString *)name;

+ (UIImage *)pf_animatedGIFWithData:(NSData *)data;

- (UIImage *)pf_animatedImageByScalingAndCroppingToSize:(CGSize)size;

- (BOOL)_isGIF;



@end
