//
//  TableViewController.m
//  PFTextView
//
//  Created by 龙鹏飞 on 2017/8/14.
//  Copyright © 2017年 https://github.com/LongPF/PFText. All rights reserved.
//

#import "TableViewController.h"
#import "PFText.h"

@interface TableViewCell : UITableViewCell

- (void)update:(NSString *)text;

@end

@interface TableViewController ()

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation TableViewController

static BOOL async = YES;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.dataArray = [NSMutableArray array];
    [self.tableView registerClass:[TableViewCell class] forCellReuseIdentifier:@"cell"];
    for (int i = 0; i < 500; i++) {
        [self.dataArray addObject:[NSString stringWithFormat:@"%@-%@",@(i).stringValue,@"🙈🙉🙊🐒🍔🍟🌭🍕⚾️🏈🏓🤺🤼‍♀️🚋🚄🚈⌚️📱📲😁😆🙄👌😎😁🤡🤠😡😠😟😞😳😔☹️🤔🤗😎🤓🤑😝😜😙🤣😇😅😂🀀🀄︎🀁🀂🀡🀗🀘🀢🀣🀤🀩🀨🀥🀦🀧🀝🀓🀀🤑🦄🐝🐛🦋🐌🐞🐸🐽🐷🐹🐵🐗🐨🐶🐱🐭🐮🦁🐯🙈🙉🙊🐒🍔🍟🌭🍕⚾️🏈🏓🤺🤼‍♀️🚋🚄🚈⌚️📱📲"]];
    }
    
    self.title = @"异步绘制";
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 40, 40);
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
    
    UISwitch *sw = [UISwitch new];
    [sw addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    [sw setOn:YES];
    UIBarButtonItem *asyncSw = [[UIBarButtonItem alloc]initWithCustomView:sw];
    self.navigationItem.rightBarButtonItem = asyncSw;
    
}

- (void)backAction:(UIButton *)button
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchAction:(UISwitch *)sw
{
    async = sw.on;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [cell update:self.dataArray[indexPath.row]];
    return cell;
}


@end

@implementation TableViewCell
{
    PFTextView *_label;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _label = [PFTextView new];
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)update:(NSString *)text
{
    _label.text = text;
    _label.displaysAsynchronously = async;
    _label.frame = self.contentView.frame;
}

@end
