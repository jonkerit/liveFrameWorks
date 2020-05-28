//
//  BJLMessageOperatorView.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/2/21.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLMessageOperatorView.h"
#import "BJLAppearance.h"

@interface BJLMessageOperatorView ()

@property (nonatomic) BOOL needTranslate;
@property (nonatomic) BOOL needShowOnlyTeacherOrAssistant;
@property (nonatomic) BJLRecallType recallType;
@property (nonatomic) BOOL canStickyMessage;

@property (nonatomic) UIView *bgView;
@property (nonatomic) UIButton *copyingButton;
@property (nonatomic) UIButton *translateButton;
@property (nonatomic) UIButton *recallButton;
@property (nonatomic) UIButton *onlyShowTeacherORAssistantMessageButton;
@property (nonatomic) UIButton *stickyMessageButton;
@property (nonatomic) NSMutableArray<UIButton *> *buttonArray;

@end

@implementation BJLMessageOperatorView

- (instancetype)initWithNeedTranslate:(BOOL)needTranslate
       needShowOnlyTeacherOrAssistant:(BOOL)needShowOnlyTeacherOrAssistant
                           recallType:(BJLRecallType)recallType
                     canStickyMessage:(BOOL)canStickyMessage {
    self = [super init];
    if (self) {
        self.needTranslate = needTranslate;
        self.needShowOnlyTeacherOrAssistant = needShowOnlyTeacherOrAssistant;
        self.recallType = recallType;
        self.canStickyMessage = canStickyMessage;
    }
    return self;
}

- (void)updateButtonConstraints {
    self.backgroundColor = [UIColor whiteColor];
    // shadow
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 5.0);
    self.layer.shadowRadius = 10.0;
    // 毛玻璃效果
    self.bgView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 4.0;
        view.layer.borderWidth = 1.0;
        view.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;
        view;
    });
    [self addSubview:self.bgView];
    [self.bgView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    self.copyingButton = [self createButtonWithTitle:@"复制"];
    [self.copyingButton addTarget:self action:@selector(copyMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    self.translateButton = [self createButtonWithTitle:@"翻译"];
    [self.translateButton addTarget:self action:@selector(translateMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    self.onlyShowTeacherORAssistantMessageButton = [self createButtonWithTitle:@"只看老师/助教"];
    [self.onlyShowTeacherORAssistantMessageButton addTarget:self action:@selector(onlyShowTeacherORAssistantMessage:) forControlEvents:UIControlEventTouchUpInside];
    
    self.recallButton = [self createButtonWithTitle:self.recallType == BJLRecallTypeDelete ? @"删除" : @"撤回"];
    [self.recallButton addTarget:self action:@selector(recallMessage:) forControlEvents:UIControlEventTouchUpInside];

    self.stickyMessageButton = [self createButtonWithTitle:@"置顶"];
    [self.stickyMessageButton addTarget:self action:@selector(stickyMessage:) forControlEvents:UIControlEventTouchUpInside];

    self.buttonArray = [@[self.copyingButton] mutableCopy];
    if (self.needTranslate) {
        [self.buttonArray addObject:self.translateButton];
    }
    
    if (self.needShowOnlyTeacherOrAssistant) {
        [self.buttonArray addObject:self.onlyShowTeacherORAssistantMessageButton];
    }
    
    if (self.recallType != BJLRecallTypeNone) {
        [self.buttonArray addObject:self.recallButton];
    }
    
    if (self.canStickyMessage) {
        [self.buttonArray addObject:self.stickyMessageButton];
    }
    
    [self makeConstraintsWithButtons:self.buttonArray];
}

- (void)copyMessage:(UIButton *)button {
    if (self.onClikCopyCallback) {
        self.onClikCopyCallback(YES);
    }
}

- (void)translateMessage:(UIButton *)button {
    if (self.onClikTranslateCallback) {
        self.onClikTranslateCallback(YES);
    }
}

- (void)onlyShowTeacherORAssistantMessage:(UIButton *)button {
    if (self.onlyShowTeacherORAssistantMessageCallback) {
        self.onlyShowTeacherORAssistantMessageCallback(YES);
    }
}

- (void)recallMessage:(UIButton *)button {
    if (self.recallMessageCallback) {
        self.recallMessageCallback(YES);
    }
}

- (void)stickyMessage:(UIButton *)button {
    if (self.stickyMessageCallback) {
        self.stickyMessageCallback(YES);
    }
}

#pragma mark - private
- (UIButton *)createButtonWithTitle:(NSString *)title {
    UIButton *button = [[UIButton alloc] init];
    button.clipsToBounds = NO;
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [button setTitleColor:[UIColor bjl_colorWithHex:0x4A4A4A] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    return button;
}

- (void)makeConstraintsWithButtons:(nullable NSArray *)buttonArray {
    if (buttonArray.count <= 0) {
        return;
    }
    UIButton *lastButton = nil;
    for (UIButton *button in buttonArray) {
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker *make) {
            make.left.right.equalTo(self);
            if (lastButton) {
                make.height.equalTo(lastButton.bjl_height);
                make.top.equalTo(lastButton.bjl_bottom);
            }
            else {
                make.height.equalTo(@(BJLMessageOperatorButtonSize)).priorityHigh();
                make.top.equalTo(self.bjl_top).offset(10.0);
            }
        }];
        lastButton = button;
    }
    [lastButton bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.bjl_bottom).offset(-10.0);
    }];
}

@end
