//
//  BJLIcQuestionResponderWindowViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/5/22.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcQuestionResponderWindowViewController.h"
#import "BJLIcQuestionResponderWindowViewController+protected.h"
#import "BJLIcQuestionResponderWindowViewController+historyList.h"
#import "BJLIcWindowViewController+protected.h"
#import "BJLIcAppearance.h"

#define onePixel (1.0 / [UIScreen mainScreen].scale)

@interface BJLIcQuestionResponderWindowViewController ()<UITextFieldDelegate>

@property (nonatomic) BJLIcQuestionResponderWindowLayout layout;

@end

@implementation BJLIcQuestionResponderWindowViewController

- (instancetype)initWithRoom:(BJLRoom *)room
                      layout:(BJLIcQuestionResponderWindowLayout)layout
         historeQuestionList:(NSArray * _Nullable)recordList {
    self = [super init];
    if (self) {
        self.layout = layout;
        self->_room = room;
        self.questionResponderList = recordList;
        [self prepareToOpen];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setWindowInterfaceEnabled:YES];
    [self setWindowGesturesEnabled:YES];
    self.forgroundView.userInteractionEnabled = NO;
    self.topBar.hidden = NO;
    
    self.maximizeButtonHidden = YES;
    self.fullscreenButtonHidden = YES;
    self.doubleTapToMaximize = NO;
    self.panToResize = NO;
    self.resizeHandleImageViewHidden = YES;
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    [self makeCommanConstraints];
    [self updateConstraints];
    [self makeObserving];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 仅用于通知上一层是否也要显示一个 overlay 来隐藏键盘，无论上层有没有，控制器内始终会显示一个 overlay
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardChangeFrameWithNotification:)
                                                 name:UIKeyboardDidChangeFrameNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self hideKeyboardView];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidChangeFrameNotification
                                                  object:nil];
}

#pragma mark - private
- (void)keyboardChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    if (self.keyboardFrameChangeCallback) {
        self.keyboardFrameChangeCallback(keyboardFrame);
    }
}

- (void)prepareToOpen {
    self.caption = @"抢答";
    self.fixedAspectRatio = 2/1;
    self.minWindowHeight = 180.0f;
    self.minWindowWidth = 360.0;
    
    CGFloat relativeWidth = 0.5f;
    CGFloat relativeHeight = [self relativeHeightWithRelativeWidth:relativeWidth width:self.minWindowWidth height:self.minWindowHeight];
    self.relativeRect = [self rectInBounds:CGRectMake(0.25, (1 - relativeHeight) / 4, relativeWidth, relativeHeight)];
}

- (void)makeCommanConstraints {
    // top bar
    self.topGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, topGapLine);
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.topBar addSubview:self.topGapLine];
    [self.topGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.left.right.equalTo(self.topBar);
        make.height.equalTo(@(onePixel));
    }];
    
    // bottom bar
    [self.bottomBar bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.height.equalTo(@(40.0));
    }];
    
    self.bottomGapLine = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomGapLine);
        view.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        bjl_return view;
    });
    [self.bottomBar addSubview:self.bottomGapLine];
    [self.bottomGapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.bottomBar);
        make.height.equalTo(@(onePixel));
    }];
    
    UITapGestureRecognizer *tapGesture = ({
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboardView)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture;
    });
    // overlay
    self.overlayView = ({
        UIView *view = [UIView new];
        view.userInteractionEnabled = YES;
        view.backgroundColor = [UIColor clearColor];
        [view addGestureRecognizer:tapGesture];
        view.accessibilityLabel = BJLKeypath(self, overlayView);
        view;
    });

    // normal
    self.editContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, editContainerView);
        bjl_return view;
    });
    
    UIView *cornerView = ({
        UIView *view = [BJLHitTestView new];
        view.clipsToBounds = YES;
        view.layer.cornerRadius = 12.0f;
        view.layer.borderWidth = onePixel;
        view.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        [self.editContainerView addSubview:view];
        bjl_return view;
    });

    self.minusButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"-" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 2, 0)];
        [button.titleLabel setFont:[UIFont systemFontOfSize:28]];
        [button addTarget:self action:@selector(minusTime) forControlEvents:UIControlEventTouchUpInside];
        [cornerView addSubview:button];
        bjl_return button;
    });
    self.plusButton = ({
        UIButton *button = [UIButton new];
        [button setTitle:@"+" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 2, 0)];
        [button.titleLabel setFont:[UIFont systemFontOfSize:28]];
        [button addTarget:self action:@selector(plusTime) forControlEvents:UIControlEventTouchUpInside];
        [cornerView addSubview:button];
        bjl_return button;
    });
    
    self.timeTextField = ({
        BJLTextField *textField = [BJLTextField new];
        textField.accessibilityLabel = BJLKeypath(self, timeTextField);
        textField.textColor = [UIColor whiteColor];
        textField.font = [UIFont systemFontOfSize:16];
        textField.textAlignment = NSTextAlignmentCenter;
        textField.layer.borderWidth = onePixel;
        textField.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        textField.textInsets = textField.editingInsets = UIEdgeInsetsMake(0, 15, 0, 15);
        textField.delegate = self;
        textField.text = @"0";
        [cornerView addSubview:textField];
        bjl_return textField;
    });
    
    UILabel *leftLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"倒计时: ";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentRight;
        [self.editContainerView addSubview:label];
        bjl_return label;
    });

    UILabel *rightLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"秒后抢答开始";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentLeft;
        [self.editContainerView addSubview:label];
        bjl_return label;
    });

    UILabel *tipLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"倒计时结束后开始抢答，设置为0时发起后立即开始抢答";
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        [self.editContainerView addSubview:label];
        bjl_return label;
    });
    [tipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.editContainerView);
        make.top.equalTo(self.editContainerView.bjl_centerY).offset(5);
        make.left.greaterThanOrEqualTo(self.editContainerView);
        make.right.lessThanOrEqualTo(self.editContainerView);
    }];
    [cornerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.editContainerView);
        make.bottom.equalTo(self.editContainerView.bjl_centerY).offset(-5);
        make.height.equalTo(@(34));
        make.left.greaterThanOrEqualTo(self.editContainerView);
        make.right.lessThanOrEqualTo(self.editContainerView);
    }];
    [self.timeTextField bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.horizontal.hugging.compressionResistance.required();
        make.center.equalTo(cornerView);
        make.top.bottom.equalTo(cornerView);
        make.width.equalTo(@(44)).priorityHigh();
    }];
    [self.plusButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.timeTextField);
        make.right.equalTo(self.timeTextField.bjl_left);
        make.height.equalTo(self.timeTextField.bjl_height);
        make.width.equalTo(@(32));
        make.left.equalTo(cornerView.bjl_left);
    }];
    [self.minusButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.timeTextField);
        make.left.equalTo(self.timeTextField.bjl_right);
        make.height.equalTo(self.timeTextField.bjl_height);
        make.width.equalTo(@(32));
        make.right.equalTo(cornerView.bjl_right);
    }];
    [leftLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.timeTextField);
        make.right.equalTo(cornerView.bjl_left).offset(-10);
        make.height.equalTo(self.timeTextField);
        make.left.greaterThanOrEqualTo(self.editContainerView);
    }];
    [rightLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.timeTextField);
        make.left.equalTo(cornerView.bjl_right).offset(10);
        make.height.equalTo(self.timeTextField);
        make.right.lessThanOrEqualTo(self.editContainerView);
    }];

    self.bottomEditContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomEditContainerView);
        [self.bottomBar addSubview:view];
        view.hidden = YES;
        bjl_return view;
    });
    
    self.publishButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, publishButton);
        button.backgroundColor = [UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0];
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"发布" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(publish) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEditContainerView addSubview:button];
        button;
    });
    self.resetButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, resetButton);
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"重置" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(reset) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEditContainerView addSubview:button];
        button;
    });
    self.editHistoryButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, editHistoryButton);
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"查看记录" forState:UIControlStateNormal];
        [button setTitle:@"返回" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
        [button addTarget:self action:@selector(showHistoryList) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomEditContainerView addSubview:button];
        button;
    });
    [self.bottomEditContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    [self.publishButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.right.equalTo(self.bottomBar).offset(-10);
        make.top.bottom.equalTo(self.bottomBar).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    [self.resetButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.right.equalTo(self.publishButton.bjl_left).offset(-10);
        make.left.greaterThanOrEqualTo(self.editHistoryButton.bjl_right).offset(10);
        make.top.bottom.equalTo(self.publishButton);
        make.width.equalTo(self.publishButton);
    }];
    [self.editHistoryButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.top.bottom.equalTo(self.publishButton);
        make.left.equalTo(self.bottomBar).offset(12);
    }];

    // publish
    self.publishingContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, publishingContainerView);
        bjl_return view;
    });
    UILabel *publishTipLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"发布成功,正在抢答...";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:18];
        label.textAlignment = NSTextAlignmentCenter;
        [self.publishingContainerView addSubview:label];
        bjl_return label;
    });
    [publishTipLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.publishingContainerView);
        make.left.greaterThanOrEqualTo(self.publishingContainerView);
        make.right.lessThanOrEqualTo(self.publishingContainerView);
    }];
    
    self.bottomPublishignContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomPublishignContainerView);
        [self.bottomBar addSubview:view];
        view.hidden = YES;
        bjl_return view;
    });
    
    self.endButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, endButton);
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        [button setTitle:@"结束" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(end) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPublishignContainerView addSubview:button];
        button;
    });
    self.revokeButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, revokeButton);
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"撤销" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(revoke) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPublishignContainerView addSubview:button];
        button;
    });
    self.publishingHistoryButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, publishingHistoryButton);
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"查看记录" forState:UIControlStateNormal];
        [button setTitle:@"返回" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showHistoryList) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomPublishignContainerView addSubview:button];
        button;
    });

    [self.bottomPublishignContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];

    [self.endButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.right.equalTo(self.bottomBar).offset(-10);
        make.top.bottom.equalTo(self.bottomBar).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    [self.revokeButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.right.equalTo(self.endButton.bjl_left).offset(-10);
        make.left.greaterThanOrEqualTo(self.publishingHistoryButton.bjl_right).offset(10);
        make.top.bottom.equalTo(self.endButton);
        make.width.equalTo(self.endButton);
    }];
    [self.publishingHistoryButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.top.bottom.equalTo(self.endButton);
        make.left.equalTo(self.bottomBar).offset(12);
    }];

    // end
    self.resultContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, resultContainerView);
        bjl_return view;
    });
    
    UIView *containerView = ({
        UIView *view = [BJLHitTestView new];
        view.backgroundColor = [UIColor clearColor];
        [self.resultContainerView addSubview:view];
        bjl_return view;
    });

    self.userNameLabel = ({
        UILabel *label  = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:24];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, userNameLabel);
        [containerView addSubview:label];
        bjl_return label;
    });
    self.noneSuccessLabel = ({
        UILabel *label  = [UILabel new];
        label.text = @"没有人抢到哦~";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:20];
        label.textAlignment = NSTextAlignmentCenter;
        label.accessibilityLabel = BJLKeypath(self, noneSuccessLabel);
        label.hidden = YES;
        [self.resultContainerView addSubview:label];
        bjl_return label;
    });
    
    self.successImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage bjlic_imageNamed:@"bjl_questionResponder_winner"]];
        [containerView addSubview:imageView];
        bjl_return imageView;
    });
    
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        [containerView addSubview:label];
        bjl_return label;
    });
    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        [label setAlpha:0.5];
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        [containerView addSubview:label];
        bjl_return label;
    });

    [containerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerX.equalTo(self.resultContainerView);
        make.top.equalTo(self.resultContainerView).offset([BJLIcAppearance sharedAppearance].userWindowDefaultBarHeight);
        make.bottom.equalTo(self.resultContainerView).offset(-40);
        make.left.greaterThanOrEqualTo(self.resultContainerView).offset(10);
        make.right.lessThanOrEqualTo(self.resultContainerView).offset(-10);
    }];
    
    [self.successImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(containerView);
        make.left.equalTo(containerView);
        make.width.equalTo(@48);
        make.height.equalTo(@48);
    }];
    [self.userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(containerView);
        make.left.equalTo(self.successImageView.bjl_right).offset(10);
        make.right.equalTo(containerView);
    }];
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.successImageView.bjl_right).offset(-5);
        make.top.equalTo(self.successImageView.bjl_bottom).offset(5);
        make.width.height.equalTo(@(12.0));
    }];

    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.groupColorLabel.bjl_right).offset(5);
        make.centerY.equalTo(self.groupColorLabel);
    }];

    [self.noneSuccessLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.resultContainerView);
        make.left.greaterThanOrEqualTo(self.resultContainerView).offset(10);
        make.right.lessThanOrEqualTo(self.resultContainerView).offset(-10);
    }];

    self.bottomResultContainerView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, bottomResultContainerView);
        [self.bottomBar addSubview:view];
        view.hidden = YES;
        bjl_return view;
    });
    
    self.reeditButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, reeditButton);
        button.layer.borderWidth = onePixel;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0x979797 alpha:0.5].CGColor;
        button.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [button setTitle:@"重新编辑" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(reedit) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomResultContainerView addSubview:button];
        button;
    });
    self.resultHistoryButton = ({
        UIButton *button = [UIButton new];
        button.layer.cornerRadius = 4.0;
        button.layer.masksToBounds = YES;
        button.accessibilityLabel = BJLKeypath(self, resultHistoryButton);
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:@"查看记录" forState:UIControlStateNormal];
        [button setTitle:@"返回" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(showHistoryList) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomResultContainerView addSubview:button];
        button;
    });

    [self.bottomResultContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.bottomBar);
    }];
    [self.reeditButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.right.equalTo(self.bottomBar).offset(-10);
        make.top.bottom.equalTo(self.bottomBar).inset(8.0);
        make.width.equalTo(@80.0);
    }];
    [self.resultHistoryButton bjl_updateConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.bottomBar);
        make.top.bottom.equalTo(self.reeditButton);
        make.left.equalTo(self.bottomBar).offset(12);
    }];
}

- (void)updateResultContainerViewWithShouldHiddenWinnerName:(nullable BJLUser *)user {
    self.noneSuccessLabel.hidden = !!user;
    self.successImageView.hidden = !user;
    self.userNameLabel.hidden = !user;
    
    UIColor *groupColor = nil;
    NSString *groupName = nil;
    for (BJLUserGroup *group in self.room.onlineUsersVM.groupList) {
        if (group.groupID == user.groupID) {
            groupColor = [UIColor bjl_colorWithHexString:group.color];
            groupName = group.name;
            break;
        }
    }
    
    self.groupColorLabel.backgroundColor = groupColor;
    self.groupNameLabel.text = groupName;
    self.groupColorLabel.hidden = !user;
    self.groupNameLabel.hidden = !user;
    
}

- (void)updateConstraints {
    self.bottomEditContainerView.hidden = (self.layout != BJLIcQuestionResponderWindowLayout_normal);
    self.bottomEditContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_normal);
    self.editContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_normal);
    self.editHistoryButton.hidden = ![self.questionResponderList count];
    self.editHistoryButton.selected = NO;

    self.bottomPublishignContainerView.hidden = (self.layout != BJLIcQuestionResponderWindowLayout_publish);
    self.bottomPublishignContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_publish);
    self.publishingContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_publish);
    self.publishingHistoryButton.hidden = ![self.questionResponderList count];
    self.publishingHistoryButton.selected = NO;

    self.bottomResultContainerView.hidden = (self.layout != BJLIcQuestionResponderWindowLayout_end);
    self.bottomResultContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_end);
    self.resultContainerView.userInteractionEnabled = (self.layout == BJLIcQuestionResponderWindowLayout_end);
    self.resultHistoryButton.hidden = ![self.questionResponderList count];
    self.resultHistoryButton.selected = NO;

    if (self.layout == BJLIcQuestionResponderWindowLayout_normal) {
        [self setContentViewController:nil contentView:self.editContainerView];
    }
    else if (self.layout == BJLIcQuestionResponderWindowLayout_publish) {
        [self setContentViewController:nil contentView:self.publishingContainerView];
    }
    else if (self.layout == BJLIcQuestionResponderWindowLayout_end) {
        [self setContentViewController:nil contentView:self.resultContainerView];
    }
    else {
//        [self setContentViewController:nil contentView:nil];
    }
}

- (void)makeObserving {
    bjl_weakify(self);
    
//    开始
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveQuestionResponderWithTime:) observer:^BOOL(NSInteger time) {
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacherOrAssistant) {
            return YES;
        }
        
        self.layout = BJLIcQuestionResponderWindowLayout_publish;
        [self updateConstraints];
        return YES;
    }];
    
//    结束
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveEndQuestionResponderWithWinner:) observer:^BOOL(BJLUser *user) {
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacherOrAssistant || (self.layout != BJLIcQuestionResponderWindowLayout_publish)) {
            return YES;
        }
        
        self.layout = BJLIcQuestionResponderWindowLayout_end;
        self.userNameLabel.text = user.displayName ?: @"";
        [self updateResultContainerViewWithShouldHiddenWinnerName:user];
        [self updateConstraints];
        
        if (user) {
            self.responderSuccessCallback(user, self.reeditButton);
        }
        [self storeQuestionRecordWithWinner:user];
        return YES;
    }];

//    撤销
    [self bjl_observe:BJLMakeMethod(self.room.roomVM, didReceiveRevokeQuestionResponder) observer:^BOOL{
        bjl_strongify(self);
        if (!self.room.loginUser.isTeacherOrAssistant || (self.layout != BJLIcQuestionResponderWindowLayout_publish)) {
            return YES;
        }
        
        self.layout = BJLIcQuestionResponderWindowLayout_normal;
        self.userNameLabel.text = nil;
        [self updateConstraints];
        return YES;
    }];
}

#pragma mark - overrite
// 点击右上角x时, 如果已发布,则需要调用callback->弹框->发布撤回抢答器的广播, 否则直接关闭即可
- (void)close {
    if (self.layout == BJLIcQuestionResponderWindowLayout_publish) {
        if (self.closeQuestionResponderCallback) {
            self.closeQuestionResponderCallback();
        }
    }
    else {
        if (self.closeCallback) {
            self.closeCallback();
        }
        [self closeWithoutRequest];
    }
}

- (void)open {
    [self openWithoutRequest];
}

#pragma mark - public
- (void)closeQuestionResponder {
    // 答题中关闭 revoke + 组件销毁同步广播
    if (self.layout == BJLIcQuestionResponderWindowLayout_publish) {
        if (self.endQuestionResponderCallback) {
            self.endQuestionResponderCallback(YES);
        }
    }
    else {
//        非答题中关闭则发送组件销毁同步广播
        if (self.closeCallback) {
            self.closeCallback();
        }
    }
    [self closeWithoutRequest];
}

- (void)hideKeyboardView {
    [self.timeTextField resignFirstResponder];
    
    if ([self.overlayView respondsToSelector:@selector(removeFromSuperview)]) {
        [self.overlayView removeFromSuperview];
    }
}

#pragma mark - action
- (void)storeQuestionRecordWithWinner:(BJLUser *)user {
    if (!user) {
        return ;
    }
    
    NSMutableArray<NSDictionary *> *list = [self.questionResponderList mutableCopy];
    if (!list) {
        list = [NSMutableArray new];
    }
    
    NSUInteger onlineUserCount = 0;
    for (BJLUser *user in self.room.onlineUsersVM.onlineUsers) {
        if (user.role == BJLUserRole_student) {
            onlineUserCount ++;
        }
    }
    
    NSDictionary *dictionary = @{
        kQuestionRecordUserKey : [[user bjlyy_modelToJSONObject] bjl_asDictionary] ?: @{},
        kQuestionRecordCountKey : @(onlineUserCount)
    };
    [list bjl_addObject:dictionary];
    self.questionResponderList = [list copy];
}

- (void)minusTime {
    NSString *time = self.timeTextField.text;
    int timeInsteger = time.intValue;
    timeInsteger = MIN(MAX(timeInsteger - 1, 0), 10);
    self.timeTextField.text = [NSString stringWithFormat:@"%i", timeInsteger];
}

- (void)plusTime {
    NSString *time = self.timeTextField.text;
    int timeInsteger = time.intValue;
    timeInsteger = MIN(MAX(timeInsteger + 1, 0), 10);
    self.timeTextField.text = [NSString stringWithFormat:@"%i", timeInsteger];
}

// 发布
- (void)publish {
    if (self.layout != BJLIcQuestionResponderWindowLayout_normal) {
        return;
    }

    NSString *timeString = self.timeTextField.text;
    NSInteger time = timeString.integerValue;
    if (time < 0 || time > 10) {
        if (self.errorCallback) {
            self.errorCallback(@"请输入0~10的抢答时间");
        }
        return;
    }

    if (self.publishQuestionResponderCallback) {
        if (!self.publishQuestionResponderCallback(time)) {
            return;
        }
    }
}

// 重置
- (void)reset {
    if (self.layout != BJLIcQuestionResponderWindowLayout_normal) {
        return;
    }

    self.timeTextField.text = @"0";
    self.userNameLabel.text = @"";
}

- (void)showHistoryList {
    BOOL hidden = !self.questionRecordView.hidden;
    
    if (hidden) {
        [self updateConstraints];
        self.questionRecordView.hidden = YES;
    }
    else {
        self.questionRecordView.hidden = NO;
        [self setContentViewController:nil contentView:self.questionRecordView];
        [self.questionRecordView reloadData];
        self.editHistoryButton.selected = (self.layout == BJLIcQuestionResponderWindowLayout_normal);
        self.publishingHistoryButton.selected = (self.layout == BJLIcQuestionResponderWindowLayout_publish);
        self.resultHistoryButton.selected = (self.layout == BJLIcQuestionResponderWindowLayout_end);
    }
}

// 结束
- (void)end {
    if (self.layout != BJLIcQuestionResponderWindowLayout_publish) {
        return;
    }

    if (self.endQuestionResponderCallback) {
        if (!self.endQuestionResponderCallback(NO)) {
            return;
        }
    }
}

// 撤销
- (void)revoke {
    if (self.layout != BJLIcQuestionResponderWindowLayout_publish) {
        return;
    }

    if (self.revokeQuestionResponderCallback) {
        if (!self.revokeQuestionResponderCallback()) {
            return;
        }
    }
}

// 重新编辑
- (void)reedit {
    if (self.layout != BJLIcQuestionResponderWindowLayout_end) {
        return;
    }
    
    self.layout = BJLIcQuestionResponderWindowLayout_normal;
    self.userNameLabel.text = @"";
    [self updateConstraints];
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.timeTextField) {
        [self.view insertSubview:self.overlayView aboveSubview:self.forgroundView];
        [self.overlayView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.timeTextField resignFirstResponder];
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *text = textField.text;
    int number = text.intValue;
    if (number >= 0 && number <= 10) {
        textField.text = [NSString stringWithFormat:@"%i", number];
    }
    else {
        textField.text = @"0";
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (![self isValidDuration:newString]) {
        return NO;
    }
    int number = newString.intValue;
    if (number >= 0 && number <= 10) {
        return YES;
    }
    return NO;
}

- (BOOL)isValidDuration:(NSString *)durationString {
    NSString *regex = @"[0-9]*";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    if ([pred evaluateWithObject:durationString]) {
        return YES;
    }
    return NO;
}

#pragma mark - get

- (UITableView *)questionRecordView {
    if (!_questionRecordView) {
        _questionRecordView = [UITableView new];
        _questionRecordView.delegate = self;
        _questionRecordView.dataSource = self;
        _questionRecordView.backgroundColor = [UIColor clearColor];
        _questionRecordView.hidden = YES;
        _questionRecordView.tableFooterView = [UIView new];
        [_questionRecordView registerClass:[BJLIcQuestionRecordCell class] forCellReuseIdentifier:NSStringFromClass([BJLIcQuestionRecordCell class])];
    }
    return _questionRecordView;
}

@end
