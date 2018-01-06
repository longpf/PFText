//
//  ViewController.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2016/11/10.
//  Copyright © 2016年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "ViewController.h"
#import "TableViewController.h"
#import "PFText.h"

#define SCREEN_SIZE [UIScreen mainScreen].bounds.size


@interface ViewController () <PFTextViewDelegate>

@property (nonatomic, strong) UILabel *logLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    PFTextView *textView = [[PFTextView alloc]initWithFrame:CGRectMake(0, 64, SCREEN_SIZE.width, 350)];
    
    textView.text = @"PFText是一个轻量级的coretext富文本展示和编辑工具。一些基本设置可参见#PFTextView.h#,其他已经实现了@nick,#tag#,linkhttps://github.com/LongPF/PFText的识别、点击操作。本地图片`penguin.png`，网络图片``http://wsqncdn.miaopai.com/upload-pic/fd83bd2c292dd2fb7e4e635f29720162.jpg``。自适应高度，粘贴板功能。注：可根据需要复写#PFTextRun#，根据特定的正则和特定的基本设置定制。\n新版本增加了#异步绘制#功能，可用于对流畅度比较高的视图\n新增gif的支持功能.包括本地gif`local_gif.gif`,网络gif``http://img4q.duitang.com/uploads/item/201502/28/20150228233429_caQnR.gif``.如果有关gif的需求为不同的索引规则,可参考PFTextLocalImageRun,PFTextInternetImageRun类继承PFTextRunDelegateRun进行配置";
    
    
    textView.lineBreakMode = NSLineBreakByTruncatingTail;
    textView.textColor = [UIColor colorWithRed:35.0/255 green:35.0/255 blue:43.0/255 alpha:1];
    textView.firstLineHeadIndent = 30;
    textView.paragraphHeadIndent = 10;
    textView.paragraphTailIndent = -10;
    textView.numberOfLines = 0;
    textView.font = [UIFont systemFontOfSize:14];
    textView.delegate = self;
    textView.enableMenuController = YES;
    
    // @nick
    PFTextAtRun *atRun = [PFTextAtRun new];
    atRun.textColor = [UIColor colorWithRed:255.0/255 green:124.0/255 blue:78.0/255 alpha:1];
    atRun.font = [UIFont systemFontOfSize:14];
    
    // link
    PFTextLinkRun *linkRun = [PFTextLinkRun new];
    linkRun.textColor = [UIColor colorWithRed:0 green:122.0/255 blue:255.0/255 alpha:1];
    linkRun.font = [UIFont boldSystemFontOfSize:14];
    
    // tag
    PFTextTagRun *tag = [PFTextTagRun new];
    tag.textColor = [UIColor colorWithRed:255.0/255 green:124.0/255 blue:78.0/255 alpha:1];
    tag.font = [UIFont boldSystemFontOfSize:14];
    
    // 本地图片 / gif
    PFTextLocalImageRun *localImageRun = [PFTextLocalImageRun new];
    localImageRun.defaultSize = CGSizeMake(30, 30);
    localImageRun.offsetY = 3;
    
    // 网络图片 / gif
    PFTextInternetImageRun *internetImageRun = [PFTextInternetImageRun new];
    internetImageRun.defaultSize = CGSizeMake(30, 30);
    internetImageRun.placeholderImage = [UIImage imageNamed:@"default"];
    internetImageRun.offsetY = 6;
    
    // 配置
    textView.settingRuns = @[atRun,localImageRun,internetImageRun,linkRun,tag];
    
    textView.backgroundColor = [UIColor colorWithRed:237.0/255 green:237.0/255 blue:237.0/255 alpha:1];
    
    [self.view addSubview:textView];
    [textView heightToFit];
    
   
    
    
    
    
    
    [self.view addSubview:self.logLabel];
    
    self.logLabel.frame = CGRectMake(15, CGRectGetMaxY(textView.frame)+30, SCREEN_SIZE.width-15*2, 44);
    
}

- (void)textView:(PFTextView *)view touchEndRun:(PFTextRun *)run
{
    NSLog(@"touchEnd %@ = %@ ",[run class],run);
    self.logLabel.text = [NSString stringWithFormat:@"%@%@  -\n          %@",@"   log : ",[run class],run];
    
    
    
    if ([run isKindOfClass:[PFTextTagRun class]] && [run.text isEqualToString:@"#异步绘制#"]) {
        TableViewController *con = [TableViewController new];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:con];
        [self presentViewController:nav animated:YES completion:nil];
    }
}

- (void)textView:(PFTextView *)view touchEnded:(UIEvent *)event
{
    
}

- (UILabel *)logLabel
{
    if (!_logLabel) {
        _logLabel = [UILabel new];
        _logLabel.textColor = [UIColor colorWithRed:35.0/255 green:35.0/255 blue:43.0/255 alpha:1];
        _logLabel.font = [UIFont systemFontOfSize:14];
        _logLabel.layer.masksToBounds = YES;
        _logLabel.layer.cornerRadius = 3;
        _logLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
        _logLabel.layer.borderWidth = 0.5;
        _logLabel.text = @"   log :";
        _logLabel.numberOfLines = 0;
    }
    return _logLabel;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
