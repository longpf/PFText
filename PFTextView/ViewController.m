//
//  ViewController.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "ViewController.h"
#import "PFTextRun.h"
#import "PFTextAtRun.h"
#import "PFTextInternetImageRun.h"
#import "PFTextLocalImageRun.h"
#import "PFTextView.h"

#define SCREEN_SIZE [UIScreen mainScreen].bounds.size


@interface ViewController () <PFTextViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    __block PFTextView *textView = [[PFTextView alloc]initWithFrame:CGRectMake(0, 40, SCREEN_SIZE.width, 350)];
    textView.text = @"当灰烬查封了凝霜的@屋檐 ,当车菊草化作深秋的露水,我用固执的枯藤做成行囊&http://wsqncdn.miaopai.com/upload-pic/fd83bd2c292dd2fb7e4e635f29720162.jpg&,走向了那布满荆棘的他乡,当大地铺满了悲泣的落叶,当杜鹃花化作远空的雾霭,#default#祝福我吧我最思念的亲人,那就是我向你告别的身影,也许迷途的惆怅会扯碎我的脚步,可我相信未来会给我一双梦想的翅膀,虽然失败的苦痛已让我遍体鳞伤,可我坚信光明就在远方";
    
    textView.lineBreakMode = NSLineBreakByTruncatingTail;
    textView.textColor = [UIColor greenColor];
    textView.firstLineHeadIndent = 30;
    textView.paragraphHeadIndent = 10;
    textView.paragraphTailIndent = -10;
    textView.numberOfLines = 7;
    textView.delegate = self;
    
    PFTextAtRun *atRun = [PFTextAtRun new];
    atRun.textColor = [UIColor blueColor];
    atRun.font = [UIFont systemFontOfSize:40];
    
    PFTextLocalImageRun *localImageRun = [PFTextLocalImageRun new];
    localImageRun.defaultSize = CGSizeMake(200, 100);
    
    PFTextInternetImageRun *internetImageRun = [PFTextInternetImageRun new];
    internetImageRun.defaultSize = CGSizeMake(100, 80);
    internetImageRun.placeholderImage = [UIImage imageNamed:@"888"];
    
    textView.settingRuns = @[atRun,localImageRun,internetImageRun];
    
    [self.view addSubview:textView];
    [textView heightToFit];
    
    
    
   
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
