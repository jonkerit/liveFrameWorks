//
//  BJLIcPromptViewController.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/11/7.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcPromptViewController.h"
#import "BJLIcPromptTableViewCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLIcPromptViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) NSMutableArray<BJLIcPromptModel *> *prompts;
@property (nonatomic, nullable) BJLIcPromptModel *specialPrompt;

@end

@implementation BJLIcPromptViewController

- (instancetype)init {
    if (self = [super init]) {
        self.prompts = [NSMutableArray new];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]]) {
            return hitView;
        }
        return nil;
    }];
    [self makeSubviewsAndConstraints];
}

- (void)makeSubviewsAndConstraints {
    // table view
    [self.tableView removeFromSuperview];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.rowHeight = [BJLIcAppearance sharedAppearance].promptCellHeiht;
    [self.tableView registerClass:[BJLIcPromptTableViewCell class] forCellReuseIdentifier:kIcPromptTableViewCellReuseIdentifier];
    [self.view addSubview:self.tableView];
    [self.tableView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.view).offset([BJLIcAppearance sharedAppearance].promptCellLargeSpace);
        make.left.right.bottom.equalTo(self.view);
    }];
}

#pragma mark - actions

- (void)enqueueWithPrompt:(NSString *)prompt {
    [self enqueueWithPrompt:prompt duration:[BJLIcAppearance sharedAppearance].promptDuration];
}

- (void)enqueueWithPrompt:(NSString *)prompt duration:(NSInteger)duration {
    [self enqueueWithPrompt:prompt duration:duration important:NO];
}

- (void)enqueueWithPrompt:(NSString *)prompt duration:(NSInteger)duration important:(BOOL)important {
    while (self.prompts.count >= [BJLIcAppearance sharedAppearance].promptCellMaxCount) {
        [self.prompts bjl_removeObjectAtIndex:[BJLIcAppearance sharedAppearance].promptCellMaxCount - 1];
    }
    // 入队新消息的时候，如果队列中存在显示时长无限的消息，移除掉这条消息
    for (BJLIcPromptModel *model in self.prompts.copy) {
        if (model.maxDuration <= 0) {
            [self.prompts removeObject:model];
        }
    }
    BJLIcPromptModel *model = [[BJLIcPromptModel alloc] initWithPrompt:prompt duration:duration important:important];
    [self.prompts bjl_insertObject:model atIndex:0];
    if (self.tableView) {
        if ([NSThread isMainThread]) {
            [self.tableView reloadData];
        }
        else {
            bjl_dispatch_async_main_queue(^{
                [self.tableView reloadData];
            });
        }
    }
}

- (void)enqueueWithSpecialPrompt:(NSString *)prompt duration:(NSInteger)duration important:(BOOL)important {
    if (prompt.length <= 0) {
        self.specialPrompt = nil;
    }
    else {
        self.specialPrompt = [[BJLIcPromptModel alloc] initWithPrompt:prompt duration:duration important:important];
    }
    if (self.tableView) {
        if ([NSThread isMainThread]) {
            [self.tableView reloadData];
        }
        else {
            bjl_dispatch_async_main_queue(^{
                [self.tableView reloadData];
            });
        }
    }
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = 0;
    switch (section) {
        case 0:
            count = (self.specialPrompt && !self.specialPrompt.reachMaxDuration) ? 1 : 0;
            break;
            
        case 1:
            count = self.prompts.count;
            break;
            
        default:
            count = 0;
            break;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIcPromptTableViewCellReuseIdentifier forIndexPath:indexPath];
    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        BJLIcPromptModel *model = [self.prompts bjl_objectAtIndex:indexPath.row];
        [bjl_as(cell, BJLIcPromptTableViewCell) updateWithPromptModel:model];
    }
    else {
        [bjl_as(cell, BJLIcPromptTableViewCell) updateWithSpecialPromptModel:self.specialPrompt];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end

NS_ASSUME_NONNULL_END
