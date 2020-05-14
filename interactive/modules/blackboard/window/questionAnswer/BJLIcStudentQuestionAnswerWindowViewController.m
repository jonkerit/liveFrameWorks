//
//  BJLIcStudentQuestionAnswerWindowViewController.m
//  BJLiveUI
//
//  Created by fanyi on 2019/6/3.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcStudentQuestionAnswerWindowViewController.h"
#import "BJLIcQuestionAnswerOptionCollectionViewCell.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define onePixel (1.0 / [UIScreen mainScreen].scale)

@interface BJLIcStudentQuestionAnswerWindowViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, readonly, weak) BJLRoom *room;
@property (nonatomic) BJLAnswerSheet *answerSheet;
@property (nonatomic) NSInteger countDownTime;
@property (nonatomic) BOOL hasSubmit;
@property (nonatomic) BOOL hasReceiveEndMessage;

@property (nonatomic) UIView *containerView;
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UILabel *commentsLabel, *countDownTimeLabel, *countDownTipLabel;
@property (nonatomic) NSTimer *countDownTimer, *leftTipTimer;

@property (nonatomic) UIView *bottomContainView;
@property (nonatomic) UIButton *submitButton;

@property (nonatomic) NSArray <BJLAnswerSheetOption *> *selectedOptions;
@property (nonatomic) UIView *answerResultContentView;
@property (nonatomic) UICollectionView *optionsResultView;

//由于判断题目下，无法区分选择的是对还是错，所以使用chooseWrong来表示我是否选择的”错“
@property (nonatomic) BOOL chooseWrong;

@end

@implementation BJLIcStudentQuestionAnswerWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                 answerSheet:(BJLAnswerSheet *)answerSheet {
    self = [super init];
    if (self) {
        self->_room = room;
        self.answerSheet = answerSheet;
        self.countDownTime = self.answerSheet.duration;
        [self prepareToOpen];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setWindowInterfaceEnabled:YES];
    [self setWindowGesturesEnabled:YES];
    self.forgroundView.userInteractionEnabled = NO;
    self.topBar.hidden = NO;
    self.bottomBar.hidden = NO;

    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.closeButtonHidden = YES;
    self.doubleTapToMaximize = NO;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];

    [self makeSubViews];
    [self makeObservering];
    [self startCountTimer];
}

- (void)dealloc {
    self.collectionView.delegate = nil;
    self.collectionView.dataSource = nil;
    
    if (self.optionsResultView) {
        self.optionsResultView.delegate = nil;
        self.optionsResultView.dataSource = nil;
    }
    
    if (self.leftTipTimer) {
        [self.leftTipTimer invalidate];
        self.leftTipTimer = nil;
    }
}

#pragma mark - private
- (void)prepareToOpen {
    self.caption = @"答题器";
    CGFloat optionHeight = [self.answerSheet.options count] < 5 ? [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight : [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + 25;
    if (self.answerSheet.questionDescription.length) {
        self.minWindowHeight = MIN(160 + optionHeight, 245);
    }
    else {
        self.minWindowHeight = 190.0;
    }
    self.minWindowWidth = 260.0;

    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    CGFloat relativeWidth = isIphone ? 0.2 : 0.3f;

    CGFloat relativeHeight = isIphone ? 0.2: [self relativeHeightWithRelativeWidth:relativeWidth width:self.minWindowWidth height:self.minWindowHeight];
    self.relativeRect = [self rectInBounds:CGRectMake(0.25, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
}

- (void)makeSubViews {
    UIView *topGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    
    [self.topBar addSubview:topGapLine];
    [topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(onePixel));
    }];

    self.containerView =({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, containerView);
        bjl_return view;
    });
    
    self.countDownTimeLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"答题计时：0:0";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, countDownTimeLabel);
        [self.containerView addSubview:label];
        bjl_return label;
    });
    [self updateCountDownShowTime];
    
    self.countDownTipLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"5秒后自动关闭";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentRight;
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, countDownTipLabel);
        [self.containerView addSubview:label];
        bjl_return label;
    });

    self.commentsLabel = ({
        UILabel *label = [UILabel new];
        label.text = self.answerSheet.questionDescription;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.accessibilityLabel = BJLKeypath(self, commentsLabel);
        [self.containerView addSubview:label];
        bjl_return label;
    });

    UIView *midderView = ({
        UIView *view = [BJLHitTestView new];
        [self.containerView addSubview:view];
        bjl_return view;
    });
    
    self.collectionView = ({
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
        view.accessibilityLabel = BJLKeypath(self, collectionView);
        [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell];
        [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong];
        [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right];
        [midderView addSubview:view];
        bjl_return view;
    });
    
    [self.countDownTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.containerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 8);
        make.right.equalTo(self.containerView).offset(-10);
        make.left.greaterThanOrEqualTo(self.countDownTimeLabel.bjl_right).offset(10);
        make.height.equalTo(@(18));
    }];

    [self.countDownTimeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.containerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 10);
        make.left.equalTo(self.containerView.bjl_left).offset(10);
        make.right.lessThanOrEqualTo(self.countDownTipLabel.bjl_left).offset(-10);
        make.height.equalTo(@(18));
    }];

    [midderView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.greaterThanOrEqualTo(self.countDownTimeLabel.bjl_bottom);
        make.centerX.left.right.equalTo(self.containerView);
        make.centerY.equalTo(self.containerView.bjl_centerY).offset(5);
        make.bottom.lessThanOrEqualTo(self.containerView).offset(-40);
    }];
    CGFloat optionsViewHeight = 0;
    CGFloat optionsViewWidth = 0;
    BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        optionsViewHeight = ([self.answerSheet.options count] <= 4
                             ? [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight
                             : [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 10 : 25)); // 1~2 行选项
        optionsViewWidth = [self.answerSheet.options count] <= 4
        ? ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.answerSheet.options count] + (isIphone ? 10 : 25) * ([self.answerSheet.options count] - 1))
        : ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 4 + (isIphone ? 10 : 25) * 3);
    }
    else {
        optionsViewHeight = 75;
        optionsViewWidth = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight*2 + 25;
    }

    [self.collectionView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.top.equalTo(midderView);
        make.height.equalTo(@(optionsViewHeight));
        make.width.equalTo(@(optionsViewWidth));
        if (!self.answerSheet.questionDescription.length) {
            make.bottom.equalTo(midderView);
        }
    }];
    
    self.commentsLabel.hidden = !self.answerSheet.questionDescription.length;
    if (self.answerSheet.questionDescription.length) {
            [self.commentsLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.vertical.hugging.compressionResistance.required();
            make.top.equalTo(self.collectionView.bjl_bottom).offset(10);
            make.left.equalTo(midderView).offset(10);
            make.right.equalTo(midderView).offset(-10);
            make.bottom.equalTo(midderView);
        }];
    }

    [self setContentViewController:nil contentView:self.containerView];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(40.0));
    }];
    
     UIView *bottomGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.bottomBar addSubview:bottomGapLine];
    [bottomGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.bottomBar);
        make.height.equalTo(@(onePixel));
    }];

    self.bottomContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomContainView);
        [self.bottomBar addSubview:view];
        bjl_return view;
    });
    self.submitButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, submitButton);
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.titleLabel.font = [UIFont systemFontOfSize:16.0];
        [button setTitle:@"提交" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"修改答案" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomContainView addSubview:button];
        bjl_return button;
    });
    
    [self.bottomContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    
    [self.submitButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.bottomContainView);
        make.top.bottom.equalTo(self.bottomContainView).inset(8.0);
        make.width.equalTo(@80.0);
    }];
}

- (void)startCountTimer {
    [self stopCountDownTimer];
    self.countDownTime --;
    
    bjl_weakify(self);
    self.countDownTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self) {
            [timer invalidate];
            return;
        }
        
        // 倒计时结束
        if (self.countDownTime <= 0) {
            [timer invalidate];
            
            if (!self.hasSubmit) {
                [self submit:YES];
            }
            // 倒计时时间到就关闭窗口
            if (!self.answerSheet.shouldShowCorrectAnswer) {
                [self closeWithoutRequest];
            }
            return;
        }
    
        [self updateCountDownShowTime];
        self.countDownTime --;
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
}

// 销毁倒计时
- (void)stopCountDownTimer {
    if (self.countDownTimer || [self.countDownTimer isValid]) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

- (void)updateCountDownShowTime{
    int minutes = ((int)self.countDownTime) / 60;
    int second = ((int)self.countDownTime) % 60;
    
    self.countDownTimeLabel.text = [NSString stringWithFormat:@"答题计时：%i:%i", minutes, second];
}

#pragma mark - oberseving
- (void)makeObservering {
    bjl_weakify(self);
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionAnswerWithEndTime:) observer:(BJLMethodObserver)^BOOL(NSTimeInterval endTime) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        [self stopCountDownTimer];
        self.hasReceiveEndMessage = YES;
        
        if (self.errorCallback) {
            self.errorCallback(@"答题器已结束");
        }
        
//        如果学生未曾提交，自动提交
        if (!self.hasSubmit) {
            [self submit:YES];
        }

        if (self.answerSheet.shouldShowCorrectAnswer) {
            [self showCorrectAnswer];
        }
        else {
            [self startTipForAutoClose];
        }
        return YES;
    }];
    
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionAnswerWithEndTime:) observer:^BOOL(NSTimeInterval endTime) {
        bjl_strongify(self);
        if (self.room.loginUser.isAudition) {
            return YES;
        }
        
        [self stopCountDownTimer];
        self.hasReceiveEndMessage = YES;

        if (self.errorCallback) {
            self.errorCallback(@"答题器已被撤销");
        }
        [self startTipForAutoClose];
        return YES;
    }];
}

- (void)startTipForAutoClose {
    self.containerView.userInteractionEnabled = NO;
    self.submitButton.backgroundColor = [UIColor bjl_colorWithHex:0X9B9B9B];
    self.countDownTipLabel.hidden = NO;
    
    bjl_weakify(self);
    __block NSInteger leftTipTime = 5;
    self.leftTipTimer = [NSTimer bjl_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        bjl_strongify(self);
        if (!self || leftTipTime <= 0) {
            [self.leftTipTimer invalidate];
            return;
        }
        
        NSString *message = [NSString stringWithFormat:@"%td秒后自动关闭", leftTipTime];
        self.countDownTipLabel.text  = message;
        leftTipTime--;
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self) {
            [self closeWithoutRequest];
        }
    });
}

- (void)updateSelectedArrayInfo {
    NSMutableArray <BJLAnswerSheetOption *> *optionsArray = [NSMutableArray new];
    
    self.chooseWrong = NO;
    for (NSInteger i = 0 ; i < [self.answerSheet.options count]; i++) {
        BJLAnswerSheetOption *option = [self.answerSheet.options bjl_objectAtIndex:i];
        if (option.key.length && option.selected) {
            [optionsArray addObject:[option copy]];
            
            if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement && i == 1 ) {
                self.chooseWrong = YES;
            }
        }
    }
    self.selectedOptions = [optionsArray copy];
}

- (void)showCorrectAnswer {
    self.caption = @"答题结果";
    
    NSString *answerString = @"";
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.key.length && option.isAnswer) {
            answerString = [answerString stringByAppendingString:option.key];
            answerString = [answerString stringByAppendingString:@" "];
        }
    }

    self.answerResultContentView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel= BJLKeypath(self, answerResultContentView);
        view;
    });

    UILabel *tipLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.text = @"我的答案";
        label;
    });
    [self.answerResultContentView addSubview:tipLabel];
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(self.answerResultContentView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight + 10);
        make.left.equalTo(self.answerResultContentView).offset(10.0);
        make.height.equalTo(@(20));
    }];
    
    UIView *view = [UIView new];
    view.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    view.layer.borderWidth = onePixel;
    view.layer.cornerRadius = 8.0;
    [self.answerResultContentView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(tipLabel.bjl_bottom).offset(10.0);
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
            
            // view
            UICollectionView *view = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
            view.backgroundColor = [UIColor clearColor];
            view.showsHorizontalScrollIndicator = NO;
            view.bounces = NO;
            view.alwaysBounceVertical = YES;
            view.pagingEnabled = YES;
            view.dataSource = self;
            view.delegate = self;
            view.userInteractionEnabled = NO;
            [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell];
            [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong];
            [view registerClass:[BJLIcQuestionAnswerOptionCollectionViewCell class] forCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right];
            view.accessibilityLabel = BJLKeypath(self, optionsResultView);
            view;
        });
        CGFloat optionsViewHeight = 0;
        CGFloat optionsViewWidth = 0;
        BOOL isIphone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            optionsViewHeight = ([self.selectedOptions count] <= 4
                                 ? [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight
                                 : [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 2 + (isIphone ? 10 : 25)); // 1~2 行选项
            optionsViewWidth = [self.selectedOptions count] <= 4
            ? ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.selectedOptions count] + (isIphone ? 10 : 25) * ([self.selectedOptions count] - 1))
            : ([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * 4 + (isIphone ? 10 : 25) * 3);
        }
        else {
            optionsViewHeight = 75;
            optionsViewWidth = [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight * [self.selectedOptions count] + 25 * ([self.selectedOptions count] - 1);
        }

        [view addSubview:self.optionsResultView];
        [self.optionsResultView bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.center.equalTo(view);
            make.height.equalTo(@(optionsViewHeight));
            make.width.equalTo(@(optionsViewWidth));
        }];
    }
    else {
        UILabel *label = ({
            UILabel *label = [[UILabel alloc] init];
            label.numberOfLines = 0;
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont systemFontOfSize:13.0];
            label.text = @"您未参与作答~";
            label;
        });
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.center.equalTo(view);
            make.left.greaterThanOrEqualTo(view);
            make.right.lessThanOrEqualTo(view);
            make.height.equalTo(@(30));
        }];
    }
    
    UILabel *correctAnswerLabel = ({
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13.0];
        label.text = [NSString stringWithFormat:@"正确答案：%@", answerString];
        label;
    });
    [self.answerResultContentView addSubview:correctAnswerLabel];
    [correctAnswerLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.top.equalTo(view.bjl_bottom).offset(10.0);
        make.left.right.equalTo(tipLabel);
        make.height.equalTo(@(20.0));
        make.bottom.equalTo(self.answerResultContentView).offset(-12.0);
    }];
    [self setContentViewController:nil contentView:self.answerResultContentView];
    self.bottomBar.hidden = YES;
    self.closeButtonHidden = NO;
}

- (void)close {
    [self closeWithoutRequest];
}

#pragma mark - action
- (void)submit {
    if (self.hasReceiveEndMessage) {
        return;
    }
    
    if (self.hasSubmit) {
        //修改答案
        if (!self.submitButton.selected) {
            //直接提交
            [self updateSelectedArrayInfo];
            self.submitButton.selected = [self submit:NO];
        }
        else {
            //清空选项数据
            self.submitButton.selected = !self.submitButton.selected;
            for (BJLAnswerSheetOption *perOption in self.answerSheet.options) {
                perOption.selected = NO;
            }
            [self.collectionView reloadData];
        }
     }
    else {
        [self updateSelectedArrayInfo];

        // 首次提交， 直接提交， 然后变为选中状态“修改答案”
        self.hasSubmit = [self submit:NO] || self.hasSubmit;
        self.submitButton.selected = self.hasSubmit;
    }
}

- (BOOL)submit:(BOOL)isAutoSubmit {
    BOOL hasSelectAnswer = NO;
    for (BJLAnswerSheetOption *option in self.answerSheet.options) {
        if (option.selected) {
            hasSelectAnswer = YES;
            break;
        }
    }
    
    if (!hasSelectAnswer) {
        if (self.errorCallback && !isAutoSubmit) {
            self.errorCallback(@"请选择答案");
        }
        return NO;
    }

    if (self.submitCallback) {
        return self.submitCallback(self.answerSheet);
    }
    
    return YES;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (collectionView == self.optionsResultView) {
        return ([self.selectedOptions count] / 4) + !!([self.selectedOptions count] % 4);
    }
    return ([self.answerSheet.options count] / 4) + !!([self.answerSheet.options count] % 4);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.optionsResultView) {
        return (([self.selectedOptions count] / 4) > section) ? 4 : ([self.selectedOptions count] % 4);
    }
    
    return (([self.answerSheet.options count] / 4) > section) ? 4 : ([self.answerSheet.options count] % 4);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.section * 4 + indexPath.row;
    if (collectionView == self.optionsResultView) {
        BJLAnswerSheetOption *option = [self.selectedOptions bjl_objectAtIndex:index];
        BJLIcQuestionAnswerOptionCollectionViewCell *cell;
        if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell forIndexPath:indexPath];
            [cell updateContentWithOptionKey:option.key isCorrect:option.isAnswer];
        }
        else {
            if (!self.chooseWrong) {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right forIndexPath:indexPath];
                [cell updateContentWithJudgOptionKey:option.key isCorrect:option.isAnswer];
            }
            else {
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong forIndexPath:indexPath];
                [cell updateContentWithJudgOptionKey:option.key isCorrect:option.isAnswer];
            }
        }
        return cell;
    }
    
    BJLAnswerSheetOption *option = [self.answerSheet.options bjl_objectAtIndex:index];
    
    BJLIcQuestionAnswerOptionCollectionViewCell *cell;
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_ChoosenCell forIndexPath:indexPath];
        [cell updateContentWithOptionKey:option.key isSelected:option.selected];
    }
    else if (self.answerSheet.answerType == BJLAnswerSheetType_Judgement) {
        if (indexPath.row == 0) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_right forIndexPath:indexPath];
            [cell updateContentWithSelected:option.selected text:option.key];
        }
        else {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:BJLIcQuestionAnswerOptionCollectionViewCellID_JudgeCell_wrong forIndexPath:indexPath];
            [cell updateContentWithSelected:option.selected text:option.key];
        }
    }
    bjl_weakify(self);
    [cell setOptionSelectedCallback:^(BOOL selected) {
        bjl_strongify(self);
        NSInteger indexInArray = indexPath.section * 4 + indexPath.row;
        BJLAnswerSheetOption *option = [self.answerSheet.options bjl_objectAtIndex:indexInArray];
        option.selected = selected;
        
        // 对错题，在选中对的一个之后， 需要把其他的置为错
        if (selected && (self.answerSheet.answerType == BJLAnswerSheetType_Judgement)) {
            for (BJLAnswerSheetOption *perOption in self.answerSheet.options) {
                if (![perOption.key isEqualToString:option.key]) {
                    perOption.selected = NO;
                }
            }
            [self.collectionView reloadData];
        }
        else if (selected && (self.answerSheet.answerType == BJLAnswerSheetType_Choosen)) {
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
                [self.collectionView reloadData];
            }
        }
    }];
    return cell ?: [collectionView dequeueReusableCellWithReuseIdentifier:@"sth new" forIndexPath:indexPath];
}

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
    CGFloat itemGap = (isIphone ? 10 : 25);
    NSInteger numberOfItems = [collectionView numberOfItemsInSection:section];
    CGFloat combinedItemWidth = (numberOfItems * itemSize.width) + ((numberOfItems - 1) * itemGap);
    if (numberOfItems < 4) {
        CGFloat padding = (collectionView.bounds.size.width - combinedItemWidth) / 2;
        CGFloat screenScale = [UIScreen mainScreen].scale;
        padding = floor(padding * screenScale) / screenScale;
        return UIEdgeInsetsMake(section != 0 ? itemGap : 0.0, padding, 0.0, 0.0);
    }
    else {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

- (CGSize)itemSize {
    if (self.answerSheet.answerType == BJLAnswerSheetType_Choosen) {
        return CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, [BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight);
    }
    else {
        return CGSizeMake([BJLIcAppearance sharedAppearance].questionAnswerOptionButtonHeight, 75);
    }
}

@end
