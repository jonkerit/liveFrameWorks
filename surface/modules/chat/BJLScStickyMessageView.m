//
//  BJLScStickyMessageView.m
//  BJLiveUI
//
//  Created by 凡义 on 2020/4/2.
//  Copyright © 2020 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLScStickyMessageView.h"
#import "BJLScAppearance.h"

@interface BJLScStickyMessageView ()<UITextViewDelegate>

@property (nonatomic) BJLMessage *message;
@property (nonatomic) BOOL canCancel;
@property (nonatomic) BOOL showcompleteMessage;

@property (nonatomic) UILabel *attributeLabel;
@property (nonatomic) UIButton *cancelSticekyButton, *gatherButton;
@property (nonatomic) UIView *messageContentView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) UIView *gapLine;

@end

@implementation BJLScStickyMessageView

- (instancetype)initWithMessage:(nullable BJLMessage *)message canCancel:(BOOL)canCancel {
    self = [super init];
    if (self) {
        self.message = message;
        self.canCancel = canCancel;
        self.showcompleteMessage = NO;
        [self makeSubviewsAndConstraints];
        [self updateMessageContent];
        [self updateSubviews];
    }
    return self;
}

#pragma mark -

- (void)makeSubviewsAndConstraints {
    self.accessibilityLabel = @"BJLScStickyMessageView";
    
    self.attributeLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 2;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        label.accessibilityLabel = BJLKeypath(self, attributeLabel);
        label.backgroundColor = [UIColor clearColor];
        label;
    });
    
    if (self.canCancel) {
        self.cancelSticekyButton = ({
            UIButton *button = [UIButton new];
            [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_cancelSticky"] forState:UIControlStateNormal];
            button.accessibilityLabel = BJLKeypath(self, cancelSticekyButton);
            [button addTarget:self action:@selector(cancelSticky) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
        [self addSubview:self.cancelSticekyButton];
    }
    
    self.messageContentView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0XF5F5F5];
        view.layer.masksToBounds = YES;
        view.layer.cornerRadius = 8.0;
        view.accessibilityLabel = BJLKeypath(self, messageContentView);
        view;
    });
    
    self.textView = ({
        UITextView *textView = [UITextView new];
        textView.textAlignment = NSTextAlignmentLeft;
        textView.font = [UIFont systemFontOfSize:12];
        textView.textColor = [UIColor bjl_colorWithHex:0X4A4A4A];
        textView.textContainerInset = UIEdgeInsetsZero;
        textView.textContainer.lineFragmentPadding = 0;
        textView.backgroundColor = [UIColor clearColor];
        textView.selectable = YES;
        textView.editable = NO;
        textView.scrollEnabled = NO;
        textView.userInteractionEnabled = YES;
        textView.delegate = self;
        textView.accessibilityLabel = BJLKeypath(self, textView);
        
        [self.messageContentView addSubview:textView];
        [textView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
        }];
        textView;
    });

    self.gatherButton = ({
        UIButton *button = [UIButton new];
        [button setImage:[UIImage bjlsc_imageNamed:@"bjl_sc_gatherSticky"] forState:UIControlStateNormal];
        button.accessibilityLabel = BJLKeypath(self, gatherButton);
        [button addTarget:self action:@selector(gatherView) forControlEvents:UIControlEventTouchUpInside];
        button;
    });
    
    self.gapLine = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor bjl_colorWithHex:0XD9D9D9];
        view.accessibilityLabel = BJLKeypath(self, gapLine);
        view;
    });
    
    [self addSubview:self.attributeLabel];
    [self addSubview:self.gapLine];

    [self.attributeLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.vertical.compressionResistance.hugging.required();
        make.top.equalTo(self).with.inset(BJLScViewSpaceS);
        make.left.equalTo(self).offset(10);
        make.right.equalTo(self).offset(-10);
        make.bottom.equalTo(self).offset(-BJLScViewSpaceS);
    }];

    [self.gapLine bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(BJLScOnePixel));
    }];

    bjl_weakify(self);
    UITapGestureRecognizer *tapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        CGPoint point = [gesture locationInView:self];
        [self handleTapGesture:point];
    }];
    [self addGestureRecognizer:tapGesture];
}

// 根据视图状态更新文本
- (void)updateMessageContent {
    if (!self.message) {
        return;
    }
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSAttributedString *firstString = [[NSAttributedString alloc] initWithString:@" 置顶 "
    attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12],
                 NSForegroundColorAttributeName: [UIColor whiteColor],
                 NSBackgroundColorAttributeName: [UIColor bjl_colorWithHex:0x1795FF]
    }];
    [string appendAttributedString:firstString];
    
    if (self.showcompleteMessage) {
        self.attributeLabel.numberOfLines = 1;
        NSString *nameString = self.message.fromUser.displayName;
        if (nameString.length) {
            NSAttributedString *spaceText = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *nameText = [[NSAttributedString alloc] initWithString:nameString attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:12],
                NSForegroundColorAttributeName: [UIColor bjl_colorWithHex:0X545454],
            }];
            [string appendAttributedString:spaceText];
            [string appendAttributedString:nameText];
        }
    }
    else {
        if (self.message.type != BJLMessageType_image) {
            self.attributeLabel.numberOfLines = 2;
            NSAttributedString *spaceText = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *messageText = [self.message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X545454]} cached:YES cachedKey:@"cache"];
            [string appendAttributedString:spaceText];
            [string appendAttributedString:messageText];
        }
        else {
            self.attributeLabel.numberOfLines = 1;
            NSAttributedString *spaceText = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *nameText = [[NSAttributedString alloc] initWithString:@"点击查看 [图片]" attributes:@{
                NSFontAttributeName: [UIFont systemFontOfSize:12],
                NSForegroundColorAttributeName: [UIColor bjl_colorWithHex:0X545454],
            }];
            [string appendAttributedString:spaceText];
            [string appendAttributedString:nameText];
        }
    }
    self.attributeLabel.attributedText = string;
    NSAttributedString *messageText = [self.message attributedEmoticonStringWithEmoticonSize:16.0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor bjl_colorWithHex:0X545454]} cached:YES cachedKey:@"cache"];
    
    self.textView.attributedText = messageText ;
    self.textView.dataDetectorTypes = (self.message.fromUser.isTeacherOrAssistant
                                       ? UIDataDetectorTypeLink
                                       : UIDataDetectorTypeNone);
}

#pragma mark - action

- (void)handleTapGesture:(CGPoint)point {
    if (self.showcompleteMessage) {
        return;
    }
    else if (!self.showcompleteMessage && self.message.type == BJLMessageType_image) {
        if (self.imageSelectCallback) {
            self.imageSelectCallback(self.message);
        }
        return;
    }
    
    self.showcompleteMessage = YES;
    [self updateMessageContent];
    [self updateSubviews];
}

// 根据视图状态更新视图
- (void)updateSubviews {
    [self.messageContentView removeFromSuperview];
    [self.gatherButton removeFromSuperview];
    self.messageContentView.hidden = !self.showcompleteMessage;
    self.gatherButton.hidden = !self.showcompleteMessage;
    self.cancelSticekyButton.hidden = !self.showcompleteMessage;
    self.textView.hidden = YES;
    [self.attributeLabel bjl_uninstallConstraints];

    if (!self.message) {
        return;
    }
    
    if (self.showcompleteMessage) {
        [self addSubview:self.messageContentView];
        [self addSubview:self.gatherButton];
        [self.cancelSticekyButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.right.top.equalTo(self);
            make.width.height.equalTo(@(24));
        }];
        
        [self.attributeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self).with.inset(BJLScViewSpaceS);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self.cancelSticekyButton.bjl_left).offset(-10);
            make.bottom.equalTo(self.messageContentView.bjl_top).offset(-BJLScViewSpaceS);
        }];

        [self.messageContentView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.attributeLabel);
            make.top.equalTo(self.attributeLabel.bjl_bottom).offset(BJLScViewSpaceS);
            make.right.lessThanOrEqualTo(self).offset(-10);
        }];
        
        [self.gatherButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self.messageContentView.bjl_bottom);
            make.centerX.bottom.equalTo(self);
            make.height.equalTo(@(24));
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
        }];
        
        self.textView.hidden = self.message.type == BJLMessageType_image;
        if (!self.textView.hidden) {
            [self.textView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
                make.top.bottom.left.right.equalTo(self.messageContentView).insets(UIEdgeInsetsMake(BJLScViewSpaceS, BJLScViewSpaceM, BJLScViewSpaceS, BJLScViewSpaceM));
            }];
        }
    }
    else {
        [self.attributeLabel bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(self).with.inset(BJLScViewSpaceS);
            make.left.equalTo(self).offset(10);
            make.right.equalTo(self).offset(-10);
            make.bottom.equalTo(self).offset(-BJLScViewSpaceS);
        }];
    }
    if (self.updateConstraintsCallback) {
        self.updateConstraintsCallback(self.showcompleteMessage);
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)cancelSticky {
    if (self.cancelStickyCallback) {
        self.cancelStickyCallback();
    }
}

// 收起
- (void)gatherView {
    [self resetStickyMessageView];
}

//更新view
- (void)updateStickyMessage:(nullable BJLMessage *)message {
    self.message = message;
    [self resetStickyMessageView];
}

// 重置view
- (void)resetStickyMessageView {
    self.showcompleteMessage = NO;
    [self updateMessageContent];
    [self updateSubviews];
}

#pragma mark - UITextViewDelegate

// 文本链接跳转
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.linkURLCallback) {
        return self.linkURLCallback(URL);
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
