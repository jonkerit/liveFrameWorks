//
//  BJLAnswerSHeetResultViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/7/23.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLAnswerSHeetResultViewController.h"
#import "BJLAppearance.h"
#import "BJLAnswerSheetOptionCell.h"

static NSString * const cellReuseIdentifier = @"resultOptionCell";

@interface BJLAnswerSHeetResultViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) BJLAnswerSheet *answerSheet;

@property (nonatomic) NSArray <BJLAnswerSheetOption *> *selectedOptions;
@property (nonatomic) UIView *answerResultContentView;
@property (nonatomic) UIView *topBar;
@property (nonatomic) UICollectionView *optionsResultView;

@property (nonatomic, readonly) CGFloat optionButtonWH;
@property (nonatomic, readonly) CGFloat optionCountForRow;

@end

@implementation BJLAnswerSHeetResultViewController

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet {
    self = [super init];
    if (self) {
        self.answerSheet = answerSheet;
        self->_optionButtonWH = (answerSheet.answerType == BJLAnswerSheetType_Judgement) ? 64.0 : 40.0;
        self->_optionCountForRow = (answerSheet.answerType == BJLAnswerSheetType_Judgement) ? 2 : 4;

        [self showCorrectAnswers];
    }
    return self;
}

- (void)dealloc {
    if (self.optionsResultView) {
        self.optionsResultView.delegate = nil;
        self.optionsResultView.dataSource = nil;
    }
}

- (void)showCorrectAnswers {
    NSMutableArray <BJLAnswerSheetOption *> *optionsArray = [NSMutableArray new];
    
    NSString *answerString = @"";
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.key.length && option.isAnswer) {
            answerString = [answerString stringByAppendingString:option.key];
            answerString = [answerString stringByAppendingString:@" "];
        }
        
        if (option.key.length && option.selected) {
            [optionsArray addObject:option];
        }
    }
    self.selectedOptions = [optionsArray copy];
        
    [self.view addSubview:self.answerResultContentView];
    [self.answerResultContentView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).priorityHigh(); // to update
        make.centerY.equalTo(self.view).multipliedBy(1.2).priorityHigh(); // to update
        make.width.equalTo(@(240.0)); // 指定宽度，高度自动计算
        // 边界限制
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
    }];
    
    UILabel *titleLabel = [self labelWithTitle:@"答题结果" color:[UIColor whiteColor]];
    [self.topBar addSubview:titleLabel];
    [titleLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.topBar).offset(10.0);
        make.centerY.equalTo(self.topBar);
    }];
    
    // close button
    UIButton *closeButton = ({
        UIButton *button = [[UIButton alloc] init];
        [button setImage:[UIImage bjl_imageNamed:@"bjl_ic_close"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(closeButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    [self.topBar addSubview:closeButton];
    [closeButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.topBar).offset(-10.0);
        make.top.bottom.equalTo(self.topBar);
    }];
    
    [self.answerResultContentView addSubview:self.topBar];
    [self.topBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.answerResultContentView);
        make.height.equalTo(@(30.0));
    }];
    
    UILabel *tipLabel = [self labelWithTitle:@"我的答案：" color:[self grayTextColor]];
    [self.answerResultContentView addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.topBar.bjl_bottom).offset(12.0);
        make.left.equalTo(self.answerResultContentView).offset(15.0);
        make.right.equalTo(self.answerResultContentView).offset(-15.0);
        make.height.equalTo(@(25));
    }];
    
    UIView *view = [UIView new];
    [self.answerResultContentView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(tipLabel.bjl_bottom).offset(18.0);
        make.left.right.equalTo(tipLabel);
        make.centerX.equalTo(self.answerResultContentView);
    }];

    if ([self.selectedOptions count]) {
        // options view
        self.optionsResultView = ({
            // layout
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            layout.sectionInset = UIEdgeInsetsZero;
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
            layout.itemSize = CGSizeMake(_optionButtonWH, _optionButtonWH);
            
            // view
            UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
            view.backgroundColor = [UIColor clearColor];
            view.showsHorizontalScrollIndicator = NO;
            view.bounces = NO;
            view.alwaysBounceVertical = YES;
            view.pagingEnabled = YES;
            view.dataSource = self;
            view.delegate = self;
            [view registerClass:[BJLAnswerSheetOptionCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
            view.accessibilityLabel = BJLKeypath(self, optionsResultView);
            view;
        });

        CGFloat optionsViewHeight = ([self.selectedOptions count] <= _optionCountForRow
                                     ? _optionButtonWH
                                     : _optionButtonWH * 2 + 15.0); // 1~2 行选项
        CGFloat optionsViewWidth = [self.selectedOptions count] <= _optionCountForRow ? ([self.selectedOptions count] * _optionButtonWH + ([self.selectedOptions count] - 1) * 15.0) : (_optionCountForRow * _optionButtonWH + (_optionCountForRow - 1) * 15.0);
        [view addSubview:self.optionsResultView];
        [self.optionsResultView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.center.equalTo(view);
            make.bottom.equalTo(view).offset(-5);
            make.top.equalTo(view).offset(5);
            make.height.equalTo(@(optionsViewHeight));
            make.width.equalTo(@(optionsViewWidth));
        }];
    }
    else {
        UILabel *label = [self labelWithTitle:@"您未参与答题~" color:[self grayTextColor]];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.left.right.equalTo(view);
            make.height.equalTo(@(30));
        }];
    }
    UILabel *correctAnswerLabel = [self labelWithTitle:[NSString stringWithFormat:@"正确答案：%@", answerString] color:[self grayTextColor]];
    [self.answerResultContentView addSubview:correctAnswerLabel];
    [correctAnswerLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(view.bjl_bottom).offset(18.0);
        make.left.right.equalTo(tipLabel);
        make.height.equalTo(@(25.0));
        make.bottom.equalTo(self.answerResultContentView).offset(-15.0);
    }];

}

#pragma mark - action
- (void)closeButtonOnClick:(UIButton *)button {
    [self close];
}

- (void)close {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.selectedOptions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLAnswerSheetOption *option = [[self.selectedOptions bjl_objectAtIndex:indexPath.row] bjl_as:[BJLAnswerSheetOption class]];
    BJLAnswerSheetOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell updateContentWithSelectedKey:option.key isCorrect:option.isAnswer];
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat combinedItemWidth = (_optionCountForRow * _optionButtonWH) + ((_optionCountForRow - 1) * 15.0);
    CGFloat padding = (collectionView.frame.size.width - combinedItemWidth) / 2;
    padding = MAX(0, padding);
    return UIEdgeInsetsMake(0, padding,0, padding);
}

#pragma mark - touch & move

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.view != self.topBar) {
        return;
    }
    
    // 当前触摸点
    CGPoint currentPoint = [touch locationInView:self.view];
    // 上一个触摸点
    CGPoint previousPoint = [touch previousLocationInView:self.view];
    
    // 更新偏移量: 需要注意的是 self.contentView 的 centerY 默认是 self.view 的 contentY 的 1.2 倍
    CGFloat offsetX = (self.answerResultContentView.center.x - self.view.center.x) + (currentPoint.x - previousPoint.x);
    CGFloat offsetY = (self.answerResultContentView.center.y - self.view.center.y*1.2) + (currentPoint.y - previousPoint.y);
    
    // 修改当前 contentView 的中点
    [self.answerResultContentView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(offsetX).priorityHigh();
        make.centerY.equalTo(self.view).multipliedBy(1.2).offset(offsetY).priorityHigh();
    }];
}

#pragma mark - getters
- (UIView *)answerResultContentView {
    if (!_answerResultContentView) {
        _answerResultContentView = [UIView new];
        _answerResultContentView.backgroundColor = [UIColor whiteColor];
        _answerResultContentView.clipsToBounds = YES;
        _answerResultContentView.layer.masksToBounds = YES;
        _answerResultContentView.layer.cornerRadius = 4.5;
        _answerResultContentView.accessibilityLabel = BJLKeypath(self, answerResultContentView);
    }
    return _answerResultContentView;
}

- (UIView *)topBar {
    if (!_topBar) {
        _topBar = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [self blueColor];
            view.accessibilityLabel = BJLKeypath(self, topBar);
            view;
        });
    }
    return _topBar;
}

#pragma mark - private

- (UILabel *)labelWithTitle:(NSString *)title color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor = color;
    label.font = [UIFont systemFontOfSize:12.0];
    label.text = title;
    return label;
}

- (UIColor *)grayTextColor {
    return [UIColor bjl_colorWithHexString:@"#666666"];
}

- (UIColor *)blueColor {
    return [UIColor bjl_colorWithHexString:@"#1694FF"];
}

@end
