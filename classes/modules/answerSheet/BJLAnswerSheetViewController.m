//
//  BJLAnswerSheetViewController.m
//  BJLiveUI
//
//  Created by HuangJie on 2018/6/8.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLAppearance.h"
#import "BJLAnswerSheetViewController.h"
#import "BJLAnswerSheetOptionCell.h"

static NSString * const cellReuseIdentifier = @"QuizOptionCell";

@interface BJLAnswerSheetViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) BJLAnswerSheet *answerSheet;
@property (nonatomic) NSTimer *countDownTimer;

@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *topBar;

@property (nonatomic) UIView *countDownView;
@property (nonatomic) UILabel *countDownTimeLabel;

@property (nonatomic) UICollectionView *optionsView;

@property (nonatomic) UILabel *commentsLabel;

@property (nonatomic) UIView *answerView;
@property (nonatomic) UILabel *answerDescriptLabel;
@property (nonatomic) UILabel *answerLabel;

@property (nonatomic) UIButton *finishButton;
@property (nonatomic) UIButton *submitButton;

@property (nonatomic, readonly) CGFloat optionButtonWH;
@property (nonatomic, readonly) CGFloat optionCountForRow;

@end

@implementation BJLAnswerSheetViewController

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet {
    self = [super init];
    if (self) {
        self.answerSheet = answerSheet;
        self->_optionButtonWH = (answerSheet.answerType == BJLAnswerSheetType_Judgement) ? 64.0 : 40.0;
        self->_optionCountForRow = (answerSheet.answerType == BJLAnswerSheetType_Judgement) ? 2 : 4;
        
        [self setupSubViews];
        [self checkSubmitButtonEnable];
        [self startCountDown];
    }
    return self;
}

- (void)dealloc {
    self.optionsView.delegate = nil;
    self.optionsView.dataSource = nil;
}

#pragma mark - subViews

- (void)setupSubViews {
    // contentView
    [self.view addSubview:self.contentView];
    [self.contentView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).priorityHigh(); // to update
        make.centerY.equalTo(self.view).multipliedBy(1.2).priorityHigh(); // to update
        make.width.equalTo(@(240.0)); // 指定宽度，高度自动计算
        // 边界限制
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
    }];
    
    // top bar
    [self.contentView addSubview:self.topBar];
    [self.topBar bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(@(30.0));
    }];
    [self setUpTopBar];
    
    // count down view
    [self.contentView addSubview:self.countDownView];
    [self.countDownView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.topBar.bjl_bottom).offset(12.0);
        make.left.equalTo(self.contentView).offset(15.0);
        make.right.equalTo(self.contentView).offset(-15.0);
        make.height.equalTo(@(30.0));
    }];
    [self setUpCountDownView];
    
    // options view
    CGFloat optionsViewHeight = (self.answerSheet.options.count <= _optionCountForRow
                                 ? _optionButtonWH
                                 : _optionButtonWH * 2 + 15.0); // 1~2 行选项
    [self.contentView addSubview:self.optionsView];
    [self.optionsView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.countDownView.bjl_bottom).offset(18.0);
        make.left.right.equalTo(self.countDownView);
        make.height.equalTo(@(optionsViewHeight));
    }];
    
    [self.contentView addSubview:self.commentsLabel];

    CGFloat height = [self.commentsLabel sizeThatFits:CGSizeMake(210, 0.0)].height;
    [self.commentsLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.optionsView.bjl_bottom).offset(12.0);
        make.left.right.equalTo(self.countDownView);
        make.height.equalTo(@(height + BJLViewSpaceS));
    }];
    
    /*
    // correct answer view
    [self.contentView addSubview:self.answerView];
    [self.answerView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.commentsLabel.bjl_bottom).offset(12.0);
        make.left.right.equalTo(self.countDownView);
        make.height.equalTo(@(30.0)); // to update
    }];
    [self setupAnswerView];
    */
    // submit button
    [self.contentView addSubview:self.submitButton];
    [self.submitButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.commentsLabel.bjl_bottom).offset(15.0);
        make.centerX.equalTo(self.contentView);
        make.size.equal.sizeOffset(CGSizeMake(196.0, 40.0));
        make.bottom.equalTo(self.contentView).offset(-15.0);
    }];
    
    // finish button
    [self.contentView addSubview:self.finishButton];
    [self.finishButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.submitButton);
    }];
}

- (void)setUpTopBar {
    // title label
    UILabel *titleLabel = [self labelWithTitle:@"答题器" color:[UIColor whiteColor]];
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
}

- (void)setUpCountDownView {
    // descript label
    UILabel *descriptLabel = [self labelWithTitle:@"答题倒计时" color:[self grayTextColor]];
    [self.countDownView addSubview:descriptLabel];
    [descriptLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.countDownView).offset(7.5);
        make.centerY.equalTo(self.countDownView);
    }];
    
    // count down time label
    [self.countDownView addSubview:self.countDownTimeLabel];
    [self.countDownTimeLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.countDownView).offset(-7.5);
        make.centerY.equalTo(self.countDownView);
    }];
}

- (void)setupAnswerView {
    // descript label
    [self.answerView addSubview:self.answerDescriptLabel];
    [self.answerDescriptLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.equalTo(self.answerView).offset(7.5);
        make.centerY.equalTo(self.answerView);
    }];
    
    // answer label
    [self.answerView addSubview:self.answerLabel];
    [self.answerLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.right.equalTo(self.answerView).offset(-7.5);
        make.centerY.equalTo(self.answerView);
    }];
}

#pragma mark - action

- (void)closeButtonOnClick:(UIButton *)button {
    [self close];
}

- (void)checkSubmitButtonEnable {
    BOOL enable = NO;
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.selected) {
            enable = YES;
            break;
        }
    }
    
    self.submitButton.enabled = enable;
    self.submitButton.backgroundColor = [UIColor bjl_colorWithHexString:enable ? @"#1694FF" : @"#D7D7D7"];
}

- (void)submitButtonOnClick:(UIButton *)button {
    if (self.submitCallback) {
        BOOL success = self.submitCallback(self.answerSheet);
        if (success) {
            // 提交之后不允许再修改答案
            self.optionsView.userInteractionEnabled = NO;
            // 隐藏提交按钮
            self.submitButton.hidden = YES;
            // 显示确定按钮
            self.finishButton.hidden = NO;
        }
    }
}

- (void)finishButtonOnClick:(UIButton *)button {
    [self close];
}

- (void)close {
    [self.countDownTimer invalidate];
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)showSelectedAnswers {
    NSString *answerString = @"";
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.key.length && option.selected) {
            answerString = [answerString stringByAppendingString:option.key];
        }
    }
    self.answerLabel.text = answerString;
}

#pragma mark - count down

- (void)startCountDown {
    if (self.countDownTimer.isValid) {
        return;
    }
    
    // 倒计时
    NSTimeInterval startTimeInterval = self.answerSheet.startTimeInterval;
    NSTimeInterval nowtimeInterval = [[NSDate date] timeIntervalSince1970];

    __block NSTimeInterval remainingTime = self.answerSheet.duration + startTimeInterval - nowtimeInterval;
    self.countDownTimeLabel.text = [self stringFromTimeInterval:remainingTime];
    NSTimeInterval countStep = 0.5;
    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:countStep repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        remainingTime -= countStep;
        self.countDownTimeLabel.text = [self stringFromTimeInterval:remainingTime];
        if (remainingTime <= 0) {
            [timer invalidate];
            [self close];
        }
    }];
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
    CGFloat offsetX = (self.contentView.center.x - self.view.center.x) + (currentPoint.x - previousPoint.x);
    CGFloat offsetY = (self.contentView.center.y - self.view.center.y*1.2) + (currentPoint.y - previousPoint.y);
    // 修改当前 contentView 的中点
    [self.contentView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.equalTo(self.view).offset(offsetX).priorityHigh();
        make.centerY.equalTo(self.view).multipliedBy(1.2).offset(offsetY).priorityHigh();
        make.width.equalTo(@(240.0)); // 指定宽度，高度自动计算
        // 边界限制
        make.top.left.greaterThanOrEqualTo(self.view);
        make.bottom.right.lessThanOrEqualTo(self.view);
    }];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.answerSheet.options.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BJLAnswerSheetOption *option = [[self.answerSheet.options bjl_objectAtIndex:indexPath.row] bjl_as:[BJLAnswerSheetOption class]];
    BJLAnswerSheetOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
    [cell updateContentWithOptionKey:option.key isSelected:option.selected];
    bjl_weakify(self);
    [cell setOptionSelectedCallback:^(BOOL selected) {
        bjl_strongify(self);
        if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
            // 判断题只能选择一个答案
            for (BJLAnswerSheetOption *option in self.answerSheet.options) {
                option.selected = NO;
            }
        }
        else if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            NSInteger answerCount = 0;
            for (BJLAnswerSheetOption *perOption in self.answerSheet.options) {
                if (perOption.isAnswer) {
                    answerCount ++;
                }
            }
            // 选择题为单选题时,选择之后需要把其他的选择清空
            if (answerCount == 1) {
                for (BJLAnswerSheetOption *perOption in self.answerSheet.options) {
                    if (![perOption.key isEqualToString:option.key]) {
                        perOption.selected = NO;
                    }
                }
            }
        }
        option.selected = selected;
        [self checkSubmitButtonEnable];
        [self showSelectedAnswers];
        [collectionView reloadData];
    }];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat combinedItemWidth = (_optionCountForRow * _optionButtonWH) + ((_optionCountForRow - 1) * 15.0);
    CGFloat padding = (collectionView.frame.size.width - combinedItemWidth) / 2;
    padding = MAX(0, padding);
    return UIEdgeInsetsMake(0, padding,0, padding);
}

#pragma mark - getters

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor whiteColor];
            view.clipsToBounds = YES;
            view.layer.masksToBounds = YES;
            view.layer.cornerRadius = 4.5;
            view.accessibilityLabel = BJLKeypath(self, contentView);
            view;
        });
    }
    return _contentView;
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

- (UIView *)countDownView {
    if (!_countDownView) {
        _countDownView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [self grayBackgroundColor];
            view.accessibilityLabel = BJLKeypath(self, countDownView);
            view;
        });
    }
    return _countDownView;
}

- (UILabel *)countDownTimeLabel {
    if (!_countDownTimeLabel) {
        _countDownTimeLabel = [self labelWithTitle:nil color:[self blueColor]];
        _countDownTimeLabel.accessibilityLabel = BJLKeypath(self, countDownTimeLabel);
    }
    return _countDownTimeLabel;
}

-  (UICollectionView *)optionsView {
    if (!_optionsView) {
        _optionsView = ({
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
            view.accessibilityLabel = BJLKeypath(self, optionsView);
            view;
        });
    }
    return _optionsView;
}

- (UILabel *)commentsLabel {
    if (!_commentsLabel) {
        _commentsLabel = [self labelWithTitle:@"" color:[self grayTextColor]];
        _commentsLabel.accessibilityLabel = BJLKeypath(self, commentsLabel);
        _commentsLabel.text = self.answerSheet.questionDescription;
        _commentsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _commentsLabel;
}

- (UIView *)answerView {
    if (!_answerView) {
        _answerView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [self grayBackgroundColor];
            view.clipsToBounds = YES;
            view.accessibilityLabel = BJLKeypath(self, answerView);
            view;
        });
    }
    return _answerView;
}

- (UILabel *)answerDescriptLabel {
    if (!_answerDescriptLabel) {
        _answerDescriptLabel = [self labelWithTitle:@"已选" color:[self grayTextColor]];
        _answerDescriptLabel.accessibilityLabel = BJLKeypath(self, answerDescriptLabel);
    }
    return _answerDescriptLabel;
}

- (UILabel *)answerLabel {
    if (!_answerLabel) {
        _answerLabel = [self labelWithTitle:@"" color:[self blueColor]];
        _answerLabel.accessibilityLabel = BJLKeypath(self, answerLabel);
    }
    return _answerLabel;
}

-  (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = ({
            UIButton *button = [self buttonWithTitle:@"确定"];
            [button addTarget:self action:@selector(finishButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
            button.backgroundColor = [self blueColor];
            button.hidden = YES;
            button.accessibilityLabel = BJLKeypath(self, finishButton);
            button;
        });
    }
    return _finishButton;
}

- (UIButton *)submitButton {
    if (!_submitButton) {
        _submitButton = [self buttonWithTitle:@"提交答案"];
        [_submitButton addTarget:self action:@selector(submitButtonOnClick:) forControlEvents:UIControlEventTouchUpInside];
        _submitButton.accessibilityLabel = BJLKeypath(self, submitButton);
    }
    return _submitButton;
}

#pragma mark - private

- (UILabel *)labelWithTitle:(NSString *)title color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textColor = color;
    label.font = [UIFont systemFontOfSize:11.0];
    label.text = title;
    return label;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    int hours = interval / 3600;
    int minums = ((long long)interval % 3600) / 60;
    int seconds = (long long)interval % 60;
    if (hours > 0) {
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minums, seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d", minums, seconds];
    }
}

- (UIButton *)buttonWithTitle:(NSString *)title {
    UIButton *button = [[UIButton alloc] init];
    button.layer.masksToBounds = YES;
    button.layer.cornerRadius = 2.0;
    button.titleLabel.font = [UIFont systemFontOfSize:11.0];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    return button;
}

- (UIColor *)grayTextColor {
    return [UIColor bjl_colorWithHexString:@"#666666"];
}

- (UIColor *)grayBackgroundColor {
    return [UIColor bjl_colorWithHexString:@"#FAFAFA"];
}

- (UIColor *)blueColor {
    return [UIColor bjl_colorWithHexString:@"#1694FF"];
}

@end
