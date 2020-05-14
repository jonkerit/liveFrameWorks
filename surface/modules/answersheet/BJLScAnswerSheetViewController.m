//
//  BJLScAnswerSheetViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/10/17.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import "BJLScWindowViewController+protected.h"

#import "BJLScAnswerSheetViewController.h"
#import "BJLScAnswerSheetCell.h"
#import "BJLScAppearance.h"

static NSString * const cellReuseIdentifier = @"answerSheetOptionCell";

@interface BJLScAnswerSheetViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) BJLAnswerSheet *answerSheet;
@property (nonatomic) NSTimer *countDownTimer;

@property (nonatomic) UIView *containerView;

@property (nonatomic) UIView *countDownView;
@property (nonatomic) UILabel *countDownTimeLabel;

@property (nonatomic) UICollectionView *optionsView;

@property (nonatomic) UILabel *commentsLabel;

@property (nonatomic) UIButton *finishButton;
@property (nonatomic) UIButton *submitButton;

@end

@implementation BJLScAnswerSheetViewController

- (instancetype)initWithAnswerSheet:(BJLAnswerSheet *)answerSheet {
    self = [super init];
    if (self) {
        self.answerSheet = answerSheet;
        [self prepareToOpen];
    }
    return self;
}

- (void)dealloc {
    self.optionsView.delegate = nil;
    self.optionsView.dataSource = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.doubleTapToMaximize = NO;
    self.forgroundView.userInteractionEnabled = NO;
    
    self.bottomBar.hidden = YES;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.topBarBackgroundViewHidden = YES;
    self.topBar.backgroundColor = [self blueColor];
    self.view.layer.cornerRadius = 8.0;
    self.view.clipsToBounds = YES;
    self.view.layer.borderWidth = BJLScOnePixel;
    self.view.layer.borderColor = [UIColor bjlsc_grayLineColor].CGColor;

    [self setupSubViews];
    [self checkSubmitButtonEnable];
    [self startCountDown];
}
#pragma mark - subViews

- (void)prepareToOpen {
    self.caption = @"答题器";
    CGFloat optionHeight = [self.answerSheet.options count] < 5 ? answerOptionButtonHeight : answerOptionButtonHeight * 2 + 15 * 2;
    if (self.answerSheet.questionDescription.length) {
        self.minWindowHeight = 240 + optionHeight;
    }
    else {
        self.minWindowHeight = 160 + optionHeight;
    }
    self.minWindowWidth = 260.0;

    CGFloat relativeWidth = 0.2;
    CGFloat relativeHeight = 0.2;
    self.relativeRect = [self rectInBounds:CGRectMake(0.25, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
}

- (void)setupSubViews {
    // top bar
    UIView *topGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });

    [self.topBar addSubview:topGapLine];
    [topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(BJLScOnePixel));
    }];

    // count down view
    [self.containerView addSubview:self.countDownView];
    [self.countDownView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(BJLScControlSize);
        make.left.equalTo(self.containerView).offset(15.0);
        make.right.equalTo(self.containerView).offset(-15.0);
        make.height.equalTo(@(30.0));
    }];
    [self setUpCountDownView];
    
    UIView *midderView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = @"midderView";
        [self.containerView addSubview:view];
        bjl_return view;
    });

    [midderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.greaterThanOrEqualTo(self.countDownView.bjl_bottom).offset(BJLScViewSpaceM);
        make.centerX.left.right.equalTo(self.containerView);
        make.centerY.equalTo(self.containerView.bjl_centerY).offset(10);
    }];

    // options view
    CGFloat optionsViewHeight = 0;
    CGFloat optionsViewWidth = 0;
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        optionsViewHeight = ([self.answerSheet.options count] <= 4
                             ? answerOptionButtonHeight
                             : answerOptionButtonHeight * 2 + (isIphone ? 10 : 15)); // 1~2 行选项
        optionsViewWidth = [self.answerSheet.options count] <= 4
        ? (answerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 15) * ([self.answerSheet.options count] - 1))
        : (answerOptionButtonHeight * 4 + (isIphone ? 10 : 15) * 3);
    }
    else {
        optionsViewHeight = answerOptionButtonHeight;
        optionsViewWidth = answerOptionButtonHeight * 2 + 15;
    }

    [midderView addSubview:self.optionsView];
    [self.optionsView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.centerX.top.equalTo(midderView);
        make.height.equalTo(@(optionsViewHeight));
        make.width.equalTo(@(optionsViewWidth));
        if (!self.answerSheet.questionDescription.length) {
            make.bottom.equalTo(midderView);
        }
    }];
    
    [self.containerView addSubview:self.commentsLabel];
    self.commentsLabel.hidden = !self.answerSheet.questionDescription.length;
    if (self.answerSheet.questionDescription.length) {
            [self.commentsLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.vertical.hugging.compressionResistance.required();
            make.top.equalTo(self.optionsView.bjl_bottom).offset(10);
            make.left.equalTo(midderView).offset(10);
            make.right.equalTo(midderView).offset(-10);
            make.bottom.equalTo(midderView);
        }];
    }
    
    // submit button
    [self.containerView addSubview:self.submitButton];
    [self.submitButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.greaterThanOrEqualTo(midderView.bjl_bottom).offset(15.0);
        make.centerX.equalTo(self.containerView);
        make.size.equal.sizeOffset(CGSizeMake(196.0, 40.0));
        make.bottom.equalTo(self.containerView).offset(-15.0);
    }];
    
    // finish button
    [self.containerView addSubview:self.finishButton];
    [self.finishButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.submitButton);
    }];
    
    [self setContentViewController:nil contentView:self.containerView];
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

#pragma mark - action

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

#pragma mark - override

- (void)close {
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (void)closeWithoutRequest {
    [self.countDownTimer invalidate];
    [super closeWithoutRequest];
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

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return ([self.answerSheet.options count] / 4) + !!([self.answerSheet.options count] % 4);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (([self.answerSheet.options count] / 4) > section) ? 4 : ([self.answerSheet.options count] % 4);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.section * 4 + indexPath.row;

    BJLAnswerSheetOption *option = [[self.answerSheet.options bjl_objectAtIndex:index] bjl_as:[BJLAnswerSheetOption class]];
    BJLScAnswerSheetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellReuseIdentifier forIndexPath:indexPath];
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
        [collectionView reloadData];
    }];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self itemSize];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                layout:(UICollectionViewFlowLayout *)collectionViewLayout
insetForSectionAtIndex:(NSInteger)section {

    CGSize itemSize = [self itemSize];
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat itemGap = (isIphone ? 10 : 15);
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:section];
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemGap);
    if (numberOfItems <= 4) {
        CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
        CGFloat screenScale = [UIScreen mainScreen].scale;
        padding = floor(padding * screenScale) / screenScale;
        return UIEdgeInsetsMake(section != 0 ? itemGap : 0.0, padding, 0.0, padding);
    }
    else {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

- (CGSize)itemSize {
    return CGSizeMake(answerOptionButtonHeight, answerOptionButtonHeight);
}

#pragma mark - window

#pragma mark - getters

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor whiteColor];
            view.clipsToBounds = YES;
            view.layer.masksToBounds = YES;
            view.accessibilityLabel = BJLKeypath(self, containerView);
            view;
        });
    }
    return _containerView;
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
            // view
            UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
            view.backgroundColor = [UIColor clearColor];
            view.showsHorizontalScrollIndicator = NO;
            view.bounces = NO;
            view.alwaysBounceVertical = YES;
            view.pagingEnabled = YES;
            view.dataSource = self;
            view.delegate = self;
            [view registerClass:[BJLScAnswerSheetCell class] forCellWithReuseIdentifier:cellReuseIdentifier];
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
    label.font = [UIFont systemFontOfSize:14.0];
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
    button.titleLabel.font = [UIFont systemFontOfSize:12.0];
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
