//
//  BJLScQuestionOptionView.m
//  BJLiveUI
//
//  Created by xijia dai on 2019/9/27.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import "BJLScQuestionOptionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLScQuestionOptionView () 

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic) BJLQuestion *question;
@property (nonatomic, nullable) BJLQuestionReply *reply;
@property (nonatomic) UIButton *replyButton, *publishButton, *copyingButton;

@end

@implementation BJLScQuestionOptionView

- (instancetype)initWithRoom:(BJLRoom *)room question:(BJLQuestion *)question reply:(nonnull BJLQuestionReply *)reply {
    if (self = [super initWithFrame:CGRectZero]) {
        self.room = room;
        self.question = question;
        self.reply = reply;
        [self makeSubviewsAndConstraints];
    }
    return self;
}

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor whiteColor];
    
    NSString *replyTitle = self.question.replies.count > 0 ? @"追加回复" : @"回复";
    NSString *publishTitle = self.question.state & BJLQuestionPublished ? @"取消发布" : @"发布";
    self.replyButton = [self makeButtonWithTitle:replyTitle selectedTitle:nil action:@selector(sendReply)];
    self.publishButton = [self makeButtonWithTitle:publishTitle selectedTitle:nil action:@selector(updatePublish:)];
    self.copyingButton = [self makeButtonWithTitle:@"复制" selectedTitle:nil action:@selector(copyQuestion)];
    [self makeConstraintsWithButtons:@[self.replyButton, self.publishButton, self.copyingButton]];
}

- (void)sendReply {
    if (self.replyCallback) {
        self.replyCallback(self.question, nil);
    }
}

- (void)updatePublish:(UIButton *)button {
    BOOL publish = self.question.state & BJLQuestionPublished;
    if (self.publishCallback) {
        self.publishCallback(self.question, !publish);
    }
}

- (void)copyQuestion {
    if (self.copyCallback) {
        self.copyCallback(self.question);
    }
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title selectedTitle:(nullable NSString *)selectedTitle action:(SEL)selector {
    UIButton *button = [UIButton new];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.titleLabel.font = [UIFont systemFontOfSize:16.0];
    [button setTitleColor:[UIColor bjl_colorWithHexString:@"#4A4A4A" alpha:1.0] forState:UIControlStateNormal];
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
    }
    if (selectedTitle) {
        [button setTitle:selectedTitle forState:UIControlStateSelected];
    }
    if (selector) {
        [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

- (void)makeConstraintsWithButtons:(nullable NSArray *)buttons {
    UIView *last = nil;
    for (UIButton *button in buttons) {
        [self addSubview:button];
        [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (last) {
                make.left.right.height.equalTo(last);
                make.top.equalTo(last.bjl_bottom);
            }
            else {
                make.left.right.top.equalTo(self);
                make.height.equalTo(@40.0).priorityHigh();
            }
        }];
        if (button == buttons.lastObject) {
            [button bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.bottom.equalTo(self);
            }];
        }
        last = button;
    }
}

- (CGSize)viewSize {
    CGFloat height = 120.0;
    return CGSizeMake(96.0, height);
}

@end

NS_ASSUME_NONNULL_END
