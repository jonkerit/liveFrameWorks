//
//  BJLNoticeEditViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-08.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/UITextView+BJLPlaceholder.h>

#import "BJLNoticeEditViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLNoticeEditViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic) UIView *emptyView, *contentView, *emptyGroupNoticeView;
@property (nonatomic) UIView *classNoticeTitleView, *groupNoticeTitleView;
@property (nonatomic) UITextView *classNoticeTextView, *groupNoticeTextView;

@property (nonatomic) UIView *editView;
@property (nonatomic) UIImageView *editImageView;
@property (nonatomic) UILabel *editTitleLabel, *noticeTextCountLabel;
@property (nonatomic) UITextView *editNoticeTextView;
@property (nonatomic, nullable) UITextField *linkTextField;

@property (nonatomic) UIButton *doneButton, *cancelEditButton;

@end

@implementation BJLNoticeEditViewController

#pragma mark - lifecycle & <BJLRoomChildViewController>

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self->_room = room;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView.alwaysBounceVertical = YES;

    [self makeSubviews];
    [self makeConstraints];
    [self makeObserving];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    if (!parent ) {
        return;
    }
    
    [self updateNotice];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameWithNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillChangeFrameNotification
                                                  object:nil];
}

- (void)keyboardWillChangeFrameWithNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo) {
        return;
    }
    
    CGRect keyboardFrame = bjl_as(userInfo[UIKeyboardFrameEndUserInfoKey], NSValue).CGRectValue;
    NSTimeInterval animationDuration = bjl_as(userInfo[UIKeyboardAnimationDurationUserInfoKey], NSNumber).doubleValue;
    UIViewAnimationOptions animationOptions = ({
        NSNumber *animationCurveNumber = bjl_as(userInfo[UIKeyboardAnimationCurveUserInfoKey], NSNumber);
        UIViewAnimationCurve animationCurve = (animationCurveNumber != nil
                                               ? animationCurveNumber.unsignedIntegerValue
                                               : UIViewAnimationCurveEaseInOut);
        // @see http://stackoverflow.com/a/19490788/456536
        animationCurve | animationCurve << 16; // @see UIViewAnimationOptionCurveXxxx
    });
    
    [self.view layoutIfNeeded];
    CGFloat offset = (CGRectGetMinY(keyboardFrame) >= CGRectGetHeight([UIScreen mainScreen].bounds)
                      ? 0.0 : - CGRectGetHeight(keyboardFrame));
    [self.scrollView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.view).with.offset(offset);
    }];
    [self.view setNeedsLayout];
    // TODO: MingLQ - animate not working
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:animationOptions
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:nil];
}

- (void)makeSubviews {    
    self.contentView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, contentView);
        [self.scrollView addSubview:view];
        view;
    });
    
    self.classNoticeTextView = ({
        UITextView *textView = [UITextView new];
        textView.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
        textView.font = [UIFont systemFontOfSize:16.0];
        textView.textColor = [UIColor bjl_darkGrayTextColor];
        textView.bjl_placeholder = @"暂无公告";
        textView.bjl_placeholderColor = textView.bjl_placeholderColor ?: [UIColor colorWithRed:0.0 green:0.0 blue:0.0980392 alpha:0.22];
        textView.textContainer.lineFragmentPadding = 0.0;
        textView.textContainerInset = UIEdgeInsetsMake(BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM);
        textView.returnKeyType = UIReturnKeyDefault;
        textView.enablesReturnKeyAutomatically = NO;
        textView.editable = NO;
        textView.bounces = NO;
        // textView.delegate = self;
        textView.layer.cornerRadius = 8;
        textView.layer.masksToBounds = YES;
        textView.accessibilityLabel = BJLKeypath(self, classNoticeTextView);
        [self.contentView addSubview:textView];
        textView;
    });
    self.groupNoticeTextView = ({
        UITextView *textView = [UITextView new];
        textView.backgroundColor = [UIColor bjl_lightGrayBackgroundColor];
        textView.font = [UIFont systemFontOfSize:16.0];
        textView.textColor = [UIColor bjl_darkGrayTextColor];
        textView.bjl_placeholder = @"暂无通知";
        textView.bjl_placeholderColor = textView.bjl_placeholderColor ?: [UIColor colorWithRed:0.0 green:0.0 blue:0.0980392 alpha:0.22];
        textView.textContainer.lineFragmentPadding = 0.0;
        textView.textContainerInset = UIEdgeInsetsMake(BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM);
        textView.returnKeyType = UIReturnKeyDefault;
        textView.enablesReturnKeyAutomatically = NO;
        textView.editable = NO;
        textView.bounces = NO;
        // textView.delegate = self;
        textView.layer.cornerRadius = 8;
        textView.layer.masksToBounds = YES;
        textView.accessibilityLabel = BJLKeypath(self, groupNoticeTextView);
        [self.contentView addSubview:textView];
        textView;
    });
    
    self.classNoticeTitleView = ({
        UIView *view = [UIView new];
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inClass"]];
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(@(18));
            make.left.centerY.equalTo(view);
        }];
        
        UILabel *label = [UILabel new];
        label.text = @"公告";
        label.textColor = [UIColor bjl_colorWithHex:0x7F7F88];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:18];
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(imageView.bjl_right).offset(10);
            make.centerY.equalTo(imageView);
            make.right.lessThanOrEqualTo(view);
        }];
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_grayLineColor];
        [view addSubview:line];
        [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.bottom.equalTo(view);
            make.height.equalTo(@(BJLOnePixel));
        }];
        view.accessibilityLabel = BJLKeypath(self, classNoticeTitleView);
        [self.contentView addSubview:view];
        view;
    });
    
    self.groupNoticeTitleView = ({
        UIView *view = [UIView new];
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inGroup"]];
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(@(18));
            make.left.centerY.equalTo(view);
        }];
        
        UILabel *label = [UILabel new];
        label.text = @"通知";
        label.textColor = [UIColor bjl_colorWithHex:0x7F7F88];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:18];
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(imageView.bjl_right).offset(10);
            make.centerY.equalTo(imageView);
            make.right.lessThanOrEqualTo(view);
        }];
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor bjl_grayLineColor];
        [view addSubview:line];
        [line bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.right.bottom.equalTo(view);
            make.height.equalTo(@(BJLOnePixel));
        }];
        
        view.accessibilityLabel = BJLKeypath(self, groupNoticeTitleView);
        [self.contentView addSubview:view];
        view;
    });
    
    self.emptyView = ({
        UIView *view = [BJLHitTestView new];
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inClass_empty"]];
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(@(16));
            make.centerY.equalTo(view);
        }];
        
        UILabel *label = [UILabel new];
        label.text = @"通知";
        label.textColor = [UIColor bjl_colorWithHex:0x7F7F88];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:20];
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(imageView.bjl_right).offset(10);
            make.centerY.equalTo(imageView);
            make.right.lessThanOrEqualTo(view);
        }];
        view.accessibilityLabel = BJLKeypath(self, emptyView);
        view;
    });
    
    self.emptyGroupNoticeView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, emptyGroupNoticeView);
        [self.view addSubview:view];
        
        UILabel *label = [UILabel new];
        label.text = @"可以点击这里发布组内通知哦~";
        label.font = [UIFont systemFontOfSize:18];
        label.textColor = [UIColor bjl_colorWithHex:0XC6C6CF];
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.centerX.top.equalTo(view);
            make.height.equalTo(@(30));
        }];
        
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjl_imageNamed:@"bjl_usergroup_open"]];
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.top.equalTo(label.bjl_bottom);
            make.width.height.equalTo(@(30));
            make.bottom.centerX.equalTo(view);
        }];
        view.hidden = YES;
        view;
    });

    self.doneButton = ({
        UIButton *button = [UIButton new];
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.backgroundColor = [UIColor bjl_colorWithHex:0x1795FF];
        button.layer.cornerRadius = 16.0;
        // if self.doneButton.selected then save
        // otherwise show valid error
        [button setTitle:@"编辑" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        // self.doneButton.selected = self.doneButton.enabled && [self isValid];
        [button setTitle:@"保存并发布" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        // self.doneButton.enabled = [self isChanged];
        [button setTitle:@"已保存" forState:UIControlStateDisabled];
        [button setTitleColor:[UIColor bjl_lightGrayTextColor] forState:UIControlStateDisabled];
        [button addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button;
    });

    self.editView = ({
        UIView *view = [BJLHitTestView new];
        view.accessibilityLabel = BJLKeypath(self, editView);
        view.hidden = YES;
        [self.scrollView addSubview:view];
        view;
    });
    
    UIView *view = [UIView new];
    self.editImageView = ({
        UIImageView *imageView = [UIImageView new];
        [imageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inGroup"]];
        [view addSubview:imageView];
        [imageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.width.height.equalTo(@(18));
            make.left.centerY.equalTo(view);
        }];
        imageView;
    });
    
    self.editTitleLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"通知";
        label.textColor = [UIColor bjl_colorWithHex:0x7F7F88];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:18];
        [view addSubview:label];
        [label bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            make.left.equalTo(self.editImageView.bjl_right).offset(10);
            make.centerY.equalTo(self.editImageView);
            make.right.lessThanOrEqualTo(view);
        }];
        label;
    });
    [self.editView addSubview:view];
    [view bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.editView);
        make.height.equalTo(@(40));
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
    }];
    
    self.editNoticeTextView = ({
        UITextView *textView = [UITextView new];
        textView.backgroundColor = [UIColor whiteColor];
        textView.font = [UIFont systemFontOfSize:16.0];
        textView.textColor = [UIColor bjl_darkGrayTextColor];
        textView.bjl_placeholder = @"输入公告内容";
        textView.textContainer.lineFragmentPadding = 0.0;
        textView.textContainerInset = UIEdgeInsetsMake(BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM, BJLViewSpaceM);
        textView.returnKeyType = UIReturnKeyDefault;
        textView.enablesReturnKeyAutomatically = NO;
        textView.bounces = NO;
         textView.delegate = self;
        textView.layer.cornerRadius = 8;
        textView.layer.masksToBounds = YES;
        textView.layer.borderColor = [UIColor bjl_colorWithHex:0XCCCCCC].CGColor;
        textView.layer.borderWidth =  1;
        textView.accessibilityLabel = BJLKeypath(self, groupNoticeTextView);
        [self.editView addSubview:textView];
        textView;
    });

    self.noticeTextCountLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"0/140";
        label.textColor = [UIColor bjl_colorWithHex:0XC6C6CF];
        label.textAlignment = NSTextAlignmentRight;
        label.font = [UIFont systemFontOfSize:18];
        label.accessibilityLabel = BJLKeypath(self, noticeTextCountLabel);
        [self.editView addSubview:label];
        bjl_return label;
    });

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (MIN(screenSize.width, screenSize.height) > 320.0) {
        self.linkTextField = ({
            BJLTextField *textField = [BJLTextField new];
            textField.font = [UIFont systemFontOfSize:14.0];
            textField.textColor = [UIColor bjl_darkGrayTextColor];
            textField.placeholder = @"请输入跳转链接";
            textField.textInsets = textField.editingInsets = UIEdgeInsetsMake(0.0, BJLViewSpaceM, 0.0, 0.0);
            textField.backgroundColor = [UIColor clearColor];
            textField.rightView = ({
                UILabel *label = [UILabel new];
                label.text = @"选填";
                label.font = [UIFont systemFontOfSize:14.0];
                label.textColor = [UIColor bjl_lightGrayTextColor];
                label.textAlignment = NSTextAlignmentLeft;
                label;
            });
            textField.rightViewMode = UITextFieldViewModeAlways;
            [textField.rightView bjl_makeConstraints:^(BJLConstraintMaker *make) {
                CGSize size = textField.rightView.intrinsicContentSize;
                size.width += BJLViewSpaceM;
                make.size.equal.sizeOffset(size);
            }];
            // textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.keyboardType = UIKeyboardTypeURL;
            textField.returnKeyType = UIReturnKeyDefault;
            textField.enablesReturnKeyAutomatically = NO;
            textField.layer.cornerRadius = 8;
            textField.layer.masksToBounds = YES;
            textField.layer.borderColor = [UIColor bjl_colorWithHex:0XCCCCCC].CGColor;
            textField.layer.borderWidth =  1;
            textField.delegate = self;
            [self.editView addSubview:textField];
            textField;
        });
    }
    self.cancelEditButton = ({
        UIButton *button = [UIButton new];
        button.titleLabel.font = [UIFont systemFontOfSize:18.0];
        button.backgroundColor = [UIColor whiteColor];
        button.layer.cornerRadius = 16.0;
        button.layer.borderColor = [UIColor bjl_colorWithHex:0xdddddd].CGColor;
        button.layer.borderWidth = 1;
        [button setTitle:@"放弃编辑" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor bjl_colorWithHex:0x9c9c9c] forState:UIControlStateNormal];
        button.hidden = YES;
        [button addTarget:self action:@selector(returnShowNotice) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        button;
    });
}

- (void)makeConstraints {
    [self.contentView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.scrollView);
    }];
    
    [self.classNoticeTitleView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.contentView).with.inset(0);
        make.height.equalTo(@(40));
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
    }];
    [self.classNoticeTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.classNoticeTitleView.bjl_bottom).with.offset(BJLViewSpaceL);
        make.left.right.equalTo(self.classNoticeTitleView);
    }];
    
    [self.groupNoticeTitleView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.classNoticeTextView.bjl_bottom).with.offset(0);
        make.height.equalTo(@(40));
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
    }];
    
    [self.groupNoticeTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.groupNoticeTitleView.bjl_bottom).with.offset(BJLViewSpaceL);
        make.left.right.equalTo(self.groupNoticeTitleView);
        make.bottom.equalTo(self.contentView).offset(-10);
    }];
    [self.emptyGroupNoticeView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.equalTo(self.doneButton.bjl_top);
        make.centerX.left.right.equalTo(self.doneButton);
    }];
    [self.doneButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.view.bjl_left).offset(20);
        make.right.equalTo(self.view.bjl_right).offset(-20);
        make.bottom.equalTo(self.view.bjl_bottom).offset(-20);
        make.height.equalTo(@(45));
    }];
    
    [self.scrollView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
        make.bottom.equalTo(self.contentView.bjl_bottom).with.offset(BJLViewSpaceL * 2);
    }];
}

- (void)udateEditView {
    BJLNotice *notice = self.room.roomVM.notice;
    if (self.room.loginUser.groupID == 0) {
        [self.editImageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inClass"]];
        [self.editTitleLabel setText:@"公告"];
        self.editNoticeTextView.text = notice.noticeText.length ? notice.noticeText : nil;
        self.linkTextField.text = [notice.linkURL absoluteString];
        self.editNoticeTextView.bjl_placeholder = @"输入公告内容";
    }
    else {
        BJLNoticeModel *myGroupNotice = nil;
        for (NSInteger i = 0; i < [notice.groupNoticeList count];i++) {
            BJLNoticeModel *item = [notice.groupNoticeList objectAtIndex:i];
            if (item.groupID == self.room.loginUser.groupID) {
                myGroupNotice = item;
                break;
            }
        }

        [self.editImageView setImage:[UIImage bjl_imageNamed:@"bjl_notice_inGroup"]];
        [self.editTitleLabel setText:@"通知"];
        self.editNoticeTextView.text = myGroupNotice.noticeText.length ? myGroupNotice.noticeText : nil;
        self.linkTextField.text = [myGroupNotice.linkURL absoluteString];
        self.editNoticeTextView.bjl_placeholder = @"输入通知内容";
    }
    self.cancelEditButton.hidden = NO;
    [self updateEditNoticeTextView];

    [self.editView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.left.right.equalTo(self.scrollView);
    }];
    
    [self.editNoticeTextView bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.editView).offset(40 + BJLViewSpaceL);
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
        make.height.equalTo(@(100));
    }];
    [self.noticeTextCountLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.bottom.right.equalTo(self.editNoticeTextView).offset(-2);
    }];

    [self.linkTextField bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.editNoticeTextView.bjl_bottom).with.offset(BJLViewSpaceL);
        make.left.right.equalTo(self.editNoticeTextView);
        make.height.equalTo(@(35));
        make.bottom.equalTo(self.editView.bjl_bottom).offset(-10);
    }];

    [self.cancelEditButton bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.right.equalTo(self.doneButton);
        make.bottom.equalTo(self.doneButton.bjl_top).offset(-10);
        make.height.equalTo(self.doneButton);
    }];
    [self.scrollView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
        make.edges.equalTo(self.view);
        make.bottom.equalTo(self.editView.bjl_bottom).with.offset(BJLViewSpaceL * 2);
    }];
    
    [self.editNoticeTextView setNeedsLayout];
    [self.editNoticeTextView layoutIfNeeded];
    
    [self.linkTextField setNeedsLayout];
    [self.linkTextField layoutIfNeeded];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)makeObserving {
    bjl_weakify(self);
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, notice)
         observer:^BOOL(BJLNotice * _Nullable notice, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateNotice];
             return YES;
         }];
    
    UITapGestureRecognizer *tagGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        [self.editNoticeTextView resignFirstResponder];
        [self.linkTextField resignFirstResponder];
    }];
    [self.scrollView addGestureRecognizer:tagGesture];
}

- (BOOL)isChanged {
    BJLNotice *notice = self.room.roomVM.notice;
    return (![self.classNoticeTextView.text ?: @"" isEqualToString:notice.noticeText ?: @""]
             || ![self.linkTextField.text ?: @"" isEqualToString:notice.linkURL.absoluteString ?: @""]);
}

- (BOOL)isValid {
    return !self.linkTextField.text.length || [self validURLWithFromString:self.linkTextField.text];
}

- (NSURL *)validURLWithFromString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (urlString.length && !url.scheme.length) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:urlString]];
    }
    return [@[@"http", @"https", @"tel", @"mailto"] containsObject:[url.scheme lowercaseString]] ? url : nil;
}

- (void)returnShowNotice {
    bjl_returnIfRobot(BJLRobotDelayS);

    self.doneButton.selected = NO;
    self.editView.hidden = YES;
    self.contentView.hidden = NO;
    self.cancelEditButton.hidden = YES;
    [self updateNotice];
}

- (void)done {
    bjl_returnIfRobot(BJLRobotDelayS);
    
    if (self.doneButton.selected) {
        NSURL *url = [self validURLWithFromString:self.linkTextField.text];
        if (url) {
            self.linkTextField.text = [url absoluteString];
        }
        
        BJLError *error = [self.room.roomVM sendNoticeWithText:self.editNoticeTextView.text linkURL:url];
        if (error) {
            if (self.errorCallback) self.errorCallback(error.localizedFailureReason ?: error.localizedDescription);
            return;
        }
        else {
            [self returnShowNotice];
        }
    }
    else {
        if (self.room.loginUser.isAssistant && self.room.loginUser.noGroup && ![self.room.roomVM getAssistantaAuthorityWithNotice]) {
            if (self.errorCallback) self.errorCallback(@"公告编辑权限已被禁用");
            return ;
        }
        
        self.doneButton.selected = YES;
        self.editView.hidden = NO;
        self.contentView.hidden = YES;
        [self udateEditView];
    }
}

- (void)updateNotice {
    if (!self.parentViewController) {
        return;
    }
    
    BJLNotice *notice = self.room.roomVM.notice;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    //大班公告
    self.classNoticeTextView.text = notice.noticeText.length ? notice.noticeText : nil;
    [self.classNoticeTextView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        CGFloat height = [self.classNoticeTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.classNoticeTextView.frame), 0.0)].height;
        make.height.equalTo(@(height + BJLViewSpaceS));
    }];
    
    [self.classNoticeTextView setNeedsLayout];
    [self.classNoticeTextView layoutIfNeeded];
    CGRect textContainerRect = UIEdgeInsetsInsetRect(self.classNoticeTextView.bounds,
                                                     self.classNoticeTextView.textContainerInset);
    self.classNoticeTextView.textContainer.size = textContainerRect.size;
    
    BJLNoticeModel *myGroupNotice = nil;
    for (NSInteger i = 0; i < [notice.groupNoticeList count];i++) {
        BJLNoticeModel *item = [notice.groupNoticeList objectAtIndex:i];
        if (item.groupID == self.room.loginUser.groupID) {
            myGroupNotice = item;
            break;
        }
    }
    // 小组通知
    self.groupNoticeTextView.text = myGroupNotice.noticeText.length ? myGroupNotice.noticeText : nil;
    [self.groupNoticeTextView bjl_updateConstraints:^(BJLConstraintMaker *make) {
        CGFloat height = [self.groupNoticeTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.groupNoticeTextView.frame), 0.0)].height;
        make.height.equalTo(@(height + BJLViewSpaceS));
    }];
    
    [self.groupNoticeTextView setNeedsLayout];
    [self.groupNoticeTextView layoutIfNeeded];
    textContainerRect = UIEdgeInsetsInsetRect(self.groupNoticeTextView.bounds,
                                              self.groupNoticeTextView.textContainerInset);
    self.groupNoticeTextView.textContainer.size = textContainerRect.size;
    
    if (!self.doneButton.selected) {
        if (self.room.loginUser.groupID == 0) {
//            大班教室，只允许编辑公告
            [self.doneButton setTitle:@"编辑" forState:UIControlStateNormal];
        }
        else {
//            分组只允许编辑通知
            [self.doneButton setTitle:@"编辑组内通知" forState:UIControlStateNormal];
        }
        
        // 助教、老师在小组时没有通知
        BOOL hasNoNoticeInGroup = (self.room.loginUser.groupID != 0) && !myGroupNotice.noticeText.length;
        self.emptyGroupNoticeView.hidden = !hasNoNoticeInGroup;

        self.groupNoticeTextView.hidden = (self.room.loginUser.groupID == 0);
        self.groupNoticeTitleView.hidden = (self.room.loginUser.groupID == 0);
        
        [self.scrollView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.view);
            make.bottom.equalTo(self.contentView.bjl_bottom).with.offset(BJLViewSpaceL * 2);
        }];
    }
    else {
        self.emptyGroupNoticeView.hidden = YES;
        [self.scrollView bjl_remakeConstraints:^(BJLConstraintMaker *make) {
            make.edges.equalTo(self.view);
            make.bottom.equalTo(self.editView.bjl_bottom).with.offset(BJLViewSpaceL * 2);
        }];
    }
}

#pragma mark - <UITextFieldDelegate>

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    /*
    if (textField == self.linkTextField) {
        [self.view endEditing:YES];
    } */
    return NO;
}

#pragma mark - <UITextViewDelegate>

- (void)textViewDidBeginEditing:(UITextView *)textView {
}

- (void)textViewDidEndEditing:(UITextView *)textView {
}

- (void)textViewDidChange:(UITextView *)textView {
    dispatch_async(dispatch_get_main_queue(), ^{
        // max length
        [self updateEditNoticeTextView];
    });
}

- (void)updateEditNoticeTextView {
    if (self.editNoticeTextView.text.length > BJLTextMaxLength_notice) {
        UITextRange *markedTextRange = self.editNoticeTextView.markedTextRange;
        if (!markedTextRange || markedTextRange.isEmpty) {
            self.editNoticeTextView.text = [self.editNoticeTextView.text substringToIndex:BJLTextMaxLength_notice];
            [self.editNoticeTextView.undoManager removeAllActions];
        }
        self.noticeTextCountLabel.text = [NSString stringWithFormat:@"%td/%td", BJLTextMaxLength_notice, BJLTextMaxLength_notice];
    }
    else {
        self.noticeTextCountLabel.text = [NSString stringWithFormat:@"%td/%td", self.editNoticeTextView.text.length, BJLTextMaxLength_notice];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    /*
    if ([text isEqualToString:@"\n"]) {
        return NO;
    } */
    return YES;
}

@end

NS_ASSUME_NONNULL_END
