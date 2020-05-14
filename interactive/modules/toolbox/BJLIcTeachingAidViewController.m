//
//  BJLIcTeachingAidViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/21.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcTeachingAidViewController.h"
#import "BJLIcAppearance.h"

static CGFloat const teachingAidButtonWith = 68.0, teachingAidButtonHeigt = 100.0;

@interface BJLIcTeachingAidViewController ()

@property (nonatomic, weak) BJLRoom *room;

@property (nonatomic) UIView *backgroungView;
@property (nonatomic) UIView *buttonContainView;
@property (nonatomic) UIButton *writingBoardButton;
@property (nonatomic) UIButton *webViewButton;
@property (nonatomic) UIButton *questionAnswerButton;
@property (nonatomic) UIButton *questionResponderButton;
@property (nonatomic) UIButton *countDownButton;

@end

@implementation BJLIcTeachingAidViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    if (self = [super init]) {
        self.room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSArray *buttons =
    self.room.roomInfo.interactiveClassTemplateType == BJLIcTemplateType_1v1 ?  @[self.webViewButton,
                                                                                   self.countDownButton]
                                                                               : @[self.webViewButton,
                                                                                   self.writingBoardButton,
                                                                                   self.questionAnswerButton,
                                                                                   self.questionResponderButton,
                                                                                   self.countDownButton];
    [self makeButtonConstraints:buttons];
}


#pragma mark - private
- (void)makeSubviews {
    // 毛玻璃效果
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIView *backgroundView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [self.view addSubview:backgroundView];
    [backgroundView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.backgroungView = ({
        UIView *view = [UIView new];
        view.accessibilityLabel = BJLKeypath(self, backgroungView);
        bjl_return view;
    });
    [self.view addSubview:self.backgroungView];
    [self.backgroungView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];

    bjl_weakify(self);
    UITapGestureRecognizer *singleTap = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        [self hide];
    }];
    [self.backgroungView addGestureRecognizer:singleTap];
    
    self.buttonContainView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, buttonContainView);
        view.backgroundColor = [UIColor clearColor];
        bjl_return view;
    });
    [self.view addSubview:self.buttonContainView];
    [self.buttonContainView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.right.left.equalTo(self.view);
    }];

    self.writingBoardButton = [self makeButtonWithTitle:@"小黑板"
                                          selectedTitle:@"小黑板"
                                                  image:[UIImage bjlic_imageNamed:@"bjl_toolbox_writingboard_normal"]
                                          selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_writingboard_normal"]
                                     accessibilityLabel:BJLKeypath(self, writingBoardButton)];
    [self.writingBoardButton addTarget:self action:@selector(clickWritingBoard:) forControlEvents:UIControlEventTouchUpInside];
    
    self.webViewButton = [self makeButtonWithTitle:@"打开网页"
                                     selectedTitle:@"打开网页"
                                             image:[UIImage bjlic_imageNamed:@"bjl_toolbox_openweb_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_openweb_normal"]
                                accessibilityLabel:BJLKeypath(self, webViewButton)];
    [self.webViewButton addTarget:self action:@selector(openWeb:) forControlEvents:UIControlEventTouchUpInside];

    self.questionAnswerButton = [self makeButtonWithTitle:@"答题器"
                                     selectedTitle:@"答题器"
                                             image:[UIImage bjlic_imageNamed:@"bjl_toolbox_questionanswer_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_questionanswer_normal"]
                                accessibilityLabel:BJLKeypath(self, webViewButton)];
    [self.questionAnswerButton addTarget:self action:@selector(questionAnswer:) forControlEvents:UIControlEventTouchUpInside];

    self.questionResponderButton = [self makeButtonWithTitle:@"抢答题"
                                     selectedTitle:@"抢答题"
                                             image:[UIImage bjlic_imageNamed:@"bjl_toolbox_questionResponder_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_questionResponder_normal"]
                                accessibilityLabel:BJLKeypath(self, webViewButton)];
    [self.questionResponderButton addTarget:self action:@selector(questionResponder:) forControlEvents:UIControlEventTouchUpInside];

    self.countDownButton = [self makeButtonWithTitle:@"计时器"
                                     selectedTitle:@"计时器"
                                             image:[UIImage bjlic_imageNamed:@"bjl_toolbox_countdown_normal"]
                                     selectedImage:[UIImage bjlic_imageNamed:@"bjl_toolbox_countdown_normal"]
                                accessibilityLabel:BJLKeypath(self, webViewButton)];
    [self.countDownButton addTarget:self action:@selector(countDown:) forControlEvents:UIControlEventTouchUpInside];

    [self.buttonContainView addSubview:self.writingBoardButton];
    [self.buttonContainView addSubview:self.webViewButton];
    [self.buttonContainView addSubview:self.questionAnswerButton];
    [self.buttonContainView addSubview:self.questionResponderButton];
    [self.buttonContainView addSubview:self.countDownButton];
}

#pragma mark - private
- (void)makeButtonConstraints:(NSArray<UIButton *> *)buttonArray {
    NSInteger count = [buttonArray count];
    if(count <= 0) {
        return;
    }
    
    CGFloat gapWidth = (CGFloat)(self.view.frame.size.width - count * teachingAidButtonWith)/(count+1);
    gapWidth = MAX(gapWidth, 0);
    
    UIButton *preButton = nil;
    for(NSInteger i = 0; i < count; i ++) {
        UIButton * button = [buttonArray objectAtIndex:i];

        if(i == 0) {
            [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.centerY.top.bottom.equalTo(self.buttonContainView);
                make.left.equalTo(self.buttonContainView).offset(gapWidth);
                make.width.equalTo(@(teachingAidButtonWith));
                make.height.equalTo(@(teachingAidButtonHeigt));
            }];
        }
        else if(i == count - 1) {
            [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.centerY.top.bottom.equalTo(self.buttonContainView);
                make.right.equalTo(self.buttonContainView.bjl_right).offset(-gapWidth);
                make.width.equalTo(@(teachingAidButtonWith));
                make.height.equalTo(@(teachingAidButtonHeigt));
            }];
        }
        else {
            [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.centerY.top.bottom.equalTo(self.buttonContainView);
                make.left.equalTo(preButton.bjl_right).offset(gapWidth);
                make.width.equalTo(@(teachingAidButtonWith));
                make.height.equalTo(@(teachingAidButtonHeigt));
            }];
        }
        preButton = button;
    }
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title
                    selectedTitle:(nullable NSString *)selectedTitle
                            image:(nullable UIImage *)image
                    selectedImage:(nullable UIImage *)selectedImage
               accessibilityLabel:(nullable NSString *)accessibilityLabel {
    BJLButton *button = [BJLVerticalButton new];
    button.midSpace = 10;
    button.layer.masksToBounds = YES;
    button.accessibilityLabel = accessibilityLabel;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0];
    button.layer.cornerRadius = 4.0;
    
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0xEDEDED] forState:UIControlStateNormal];
    }
    if (selectedTitle) {
        [button setTitle:selectedTitle forState:UIControlStateSelected];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted];
        [button setTitle:selectedTitle forState:UIControlStateHighlighted | UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateSelected];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor bjl_colorWithHexString:@"#1795FF" alpha:1.0] forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    if (image) {
        [button setImage:image forState:UIControlStateNormal];
    }
    if (selectedImage) {
        [button setImage:selectedImage forState:UIControlStateSelected];
        [button setImage:selectedImage forState:UIControlStateHighlighted];
        [button setImage:selectedImage forState:UIControlStateHighlighted | UIControlStateSelected];
    }
    return button;
}

#pragma mark - action
- (void)hide {
    if (self.hideCallback) {
        self.hideCallback();
    }
    [self bjl_removeFromParentViewControllerAndSuperiew];
}

- (void)openWeb:(UIButton *)button {
    if(self.openWebViewCallback) {
        self.openWebViewCallback();
    }
    [self hide];
}

- (void)clickWritingBoard:(UIButton *)button {
    if(self.clickWritingBoardCallback) {
        self.clickWritingBoardCallback();
    }
    [self hide];
}

- (void)questionAnswer:(UIButton *)button {
    if(self.questionAnswerCallback) {
        self.questionAnswerCallback();
    }
    [self hide];
}

- (void)questionResponder:(UIButton *)button {
    if(self.questionResponderCallback) {
        self.questionResponderCallback();
    }
    [self hide];
}

- (void)countDown:(UIButton *)button {
    if(self.countDownCallback) {
        self.countDownCallback();
    }
    [self hide];
}

@end

