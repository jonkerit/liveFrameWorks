//
//  BJLNoticeViewController.m
//  BJLiveUI
//
//  Created by MingLQ on 2017-03-08.
//  Copyright © 2017 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/UITextView+BJLPlaceholder.h>

#import "BJLNoticeViewController.h"

#import "BJLOverlayViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BJLNoticeViewController ()

@property (nonatomic, readonly, weak) BJLRoom *room;

@property (nonatomic) UIView *emptyView, *classNoticeTitleView, *groupNoticeTitleView;
@property (nonatomic) UITextView *classNoticeTextView, *groupNoticeTextView;
@property (nonatomic) UILabel *classTipsLabel, *groupTipLabel;

@end

@implementation BJLNoticeViewController

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
    [self makeActions];
    [self makeObserving];
}

- (void)didMoveToParentViewController:(nullable UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    
    if (!parent && !self.bjl_overlayContainerController) {
        return;
    }
    
//    [self.bjl_overlayContainerController updateTitle:@"公告"];
    [self.bjl_overlayContainerController updateRightButtons:nil];
    [self.bjl_overlayContainerController updateFooterView:nil];
    
    [self updateNotice];
}

- (void)makeSubviews {
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
        textView.layer.cornerRadius = BJLButtonCornerRadius;
        textView.layer.masksToBounds = YES;
        textView.accessibilityLabel = BJLKeypath(self, classNoticeTextView);
        [self.scrollView addSubview:textView];
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
        textView.layer.cornerRadius = BJLButtonCornerRadius;
        textView.layer.masksToBounds = YES;
        textView.accessibilityLabel = BJLKeypath(self, groupNoticeTextView);
        [self.scrollView addSubview:textView];
        textView;
    });

    self.classTipsLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"点击公告可以跳转";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_grayBorderColor];
        label.textAlignment = NSTextAlignmentRight;
        label.accessibilityLabel = BJLKeypath(self, classTipsLabel);
        [self.scrollView addSubview:label];
        label;
    });
    self.groupTipLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"点击通知可以跳转";
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_grayBorderColor];
        label.textAlignment = NSTextAlignmentRight;
        label.accessibilityLabel = BJLKeypath(self, groupTipLabel);
        [self.scrollView addSubview:label];
        label;
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
        [self.scrollView addSubview:view];
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
        [self.scrollView addSubview:view];
        view;
    });

    self.emptyView = ({
        UIView *view = [UIView new];
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
}

- (void)makeConstraints {
    [self.classNoticeTitleView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.scrollView).with.inset(0);
        make.height.equalTo(@(40));
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
    }];
    [self.classNoticeTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.classNoticeTitleView.bjl_bottom).with.offset(BJLViewSpaceL);
        make.left.right.equalTo(self.classNoticeTitleView);
    }];
    [self.classTipsLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.classNoticeTitleView);
        make.top.equalTo(self.classNoticeTextView.bjl_bottom).with.offset(BJLViewSpaceM);
    }];

    [self.groupNoticeTitleView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.classTipsLabel.bjl_bottom).with.offset(0);
        make.height.equalTo(@(40));
        make.left.right.equalTo(@[self.view.bjl_safeAreaLayoutGuide ?: self.view, self.scrollView]).with.inset(BJLViewSpaceL);
    }];
    
    [self.groupNoticeTextView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.top.equalTo(self.groupNoticeTitleView.bjl_bottom).with.offset(BJLViewSpaceL);
        make.left.right.equalTo(self.groupNoticeTitleView);
    }];
    
    [self.groupTipLabel bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.left.right.equalTo(self.groupNoticeTitleView);
        make.top.equalTo(self.groupNoticeTextView.bjl_bottom).with.offset(BJLViewSpaceM);
    }];

    [self.scrollView bjl_makeConstraints:^(BJLConstraintMaker *make) {
        make.bottom.equalTo(self.groupTipLabel.bjl_bottom).with.offset(BJLViewSpaceL * 2);
    }];
}

- (void)makeActions {
    bjl_weakify(self);
    UITapGestureRecognizer *classTapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        if (self.room.roomVM.notice.linkURL) {
            UIApplication *application = [UIApplication sharedApplication];
            if (@available(iOS 10.0, *)) {
                [application openURL:self.room.roomVM.notice.linkURL
                             options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO}
                   completionHandler:nil];
            }
            else if ([application canOpenURL:self.room.roomVM.notice.linkURL]) {
                [application openURL:self.room.roomVM.notice.linkURL];
            }
        }
    }];
    [self.classNoticeTextView addGestureRecognizer:classTapGesture];
    
    UITapGestureRecognizer *groupTapGesture = [UITapGestureRecognizer bjl_gestureWithHandler:^(__kindof UIGestureRecognizer * _Nullable gesture) {
        bjl_strongify(self);
        BJLNoticeModel *myGroupNotice = nil;
        for (NSInteger i = 0; i < [self.room.roomVM.notice.groupNoticeList count];i++) {
            BJLNoticeModel *item = [self.room.roomVM.notice.groupNoticeList objectAtIndex:i];
            if (item.groupID == self.room.loginUser.groupID) {
                myGroupNotice = item;
                break;
            }
        }

        if (myGroupNotice.linkURL) {
            UIApplication *application = [UIApplication sharedApplication];
            if (@available(iOS 10.0, *)) {
                [application openURL:myGroupNotice.linkURL
                             options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @NO}
                   completionHandler:nil];
            }
            else if ([application canOpenURL:myGroupNotice.linkURL]) {
                [application openURL:myGroupNotice.linkURL];
            }
        }
    }];
    [self.groupNoticeTextView addGestureRecognizer:groupTapGesture];
}

- (void)makeObserving {
    bjl_weakify(self);
    
    [self bjl_kvo:BJLMakeProperty(self.room.roomVM, notice)
         observer:^BOOL(BJLNotice * _Nullable notice, id _Nullable old, BJLPropertyChange * _Nullable change) {
             bjl_strongify(self);
             [self updateNotice];
             return YES;
         }];
}

- (void)updateNotice {
    if (!self.parentViewController) {
        return;
    }
    
    BJLNotice *notice = self.room.roomVM.notice;

    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
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
    
    self.classTipsLabel.hidden = !notice.linkURL;
    
    BJLNoticeModel *myGroupNotice = nil;
    for (NSInteger i = 0; i < [notice.groupNoticeList count] ; i++) {
        BJLNoticeModel *item = [notice.groupNoticeList bjl_objectAtIndex:i];
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
    
    self.groupNoticeTextView.hidden = (self.room.loginUser.groupID == 0);
    self.groupNoticeTitleView.hidden = (self.room.loginUser.groupID == 0);
    self.groupTipLabel.hidden = !myGroupNotice.linkURL;
}

@end

NS_ASSUME_NONNULL_END
