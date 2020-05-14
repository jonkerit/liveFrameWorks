//
//  BJLIcWritingBoardBottomToolBarViewController.m
//  BJLiveUI
//
//  Created by 凡义 on 2019/3/19.
//  Copyright © 2019 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>
#import <BJLiveCore/BJLiveCore.h>

#import "BJLIcWritingBoardBottomToolBarViewController.h"

static CGFloat const WriteBoardToolBarButtonHeight = 24;

@interface BJLIcWritingBoardBottomToolBarViewController ()

@property (nonatomic, weak) BJLRoom *room;
@property (nonatomic, assign) BJLIcWriteBoardStatus barStyle;

@property (nonatomic, readwrite) UIButton
//*pictureButton,
*clearButton,
*nextPageButton,
*prevPageButton,
*revokeButton,
*gatherButton,
*submitButton,
*publishButton,
*reEditButton,
*rePublishButton,
*closeButton,
*restrictTimeButton,
*showNickNameButton     
;
@property (nonatomic, readwrite) UILabel *pageNumberLabel, *timeForStuLabel, *timeForTeachLabel;

@property (nonatomic, readwrite) NSString *restrictTime;

@property (nonatomic) UIView *containView;

@end

@implementation BJLIcWritingBoardBottomToolBarViewController

- (instancetype)initWithRoom:(BJLRoom *)room {
    self = [super init];
    if (self) {
        self.room = room;
        self.barStyle = BJLIcWriteBoardStatus_None;
    }
    return self;
}

- (void)loadView {
    self.view = [BJLHitTestView viewWithTitTestBlock:^UIView * _Nullable(UIView * _Nullable hitView, CGPoint point, UIEvent * _Nullable event) {
        if ([hitView isKindOfClass:[UIButton class]] || [hitView isKindOfClass:[UITextField class]]) {
            return hitView;
        }
        return nil;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityLabel = NSStringFromClass(self.class);
    [self.view setBackgroundColor:[UIColor bjl_colorWithHex:0x9b9b9b alpha:0.2]];

    [self makeSubviews];
}

- (void)makeSubviews {
//    self.pictureButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_choosePic_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_choosePic_selected"]];
    
    self.clearButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"bjl_ic_boardclear_normal"] selectedImage:[UIImage bjlic_imageNamed:@"bjl_ic_boardclear_selected"]];
    
    self.containView = ({
        UIView * view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.accessibilityLabel = BJLKeypath(self, containView);
        bjl_return view;
    });
    
    //teacher
    self.nextPageButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"window_nextpage"] selectedImage:[UIImage bjlic_imageNamed:@"window_nextpage"]];
    
    self.prevPageButton = [self makeImageButton:[UIImage bjlic_imageNamed:@"window_prevpage"] selectedImage:[UIImage bjlic_imageNamed:@"window_prevpage"]];
    
    self.revokeButton = [self makeButtonWithTitle:@"撤销" selectedTitle:@"撤销" image:nil selectedImage:nil accessibilityLabel:@"revokeButton"];
    self.revokeButton.layer.borderColor = [UIColor bjl_colorWithHex:0x979797].CGColor;
    self.revokeButton.layer.borderWidth = BJL1Pixel();

    self.gatherButton = [self makeButtonWithTitle:@"收回" selectedTitle:@"收回" image:nil selectedImage:nil accessibilityLabel:@"gatherButton"];
    self.gatherButton.layer.borderColor = [UIColor bjl_colorWithHex:0x979797].CGColor;
    self.gatherButton.layer.borderWidth = BJL1Pixel();

    self.reEditButton = [self makeButtonWithTitle:@"重新编辑" selectedTitle:@"重新编辑" image:nil selectedImage:nil accessibilityLabel:@"reEditButton"];
    self.reEditButton.layer.borderColor = [UIColor bjl_colorWithHex:0x979797].CGColor;
    self.reEditButton.layer.borderWidth = BJL1Pixel();
    
    self.rePublishButton = [self makeButtonWithTitle:@"再次发布" selectedTitle:@"再次发布" image:nil selectedImage:nil accessibilityLabel:@"rePublishButton"];
    self.rePublishButton.layer.borderColor = [UIColor bjl_colorWithHex:0x979797].CGColor;
    self.rePublishButton.layer.borderWidth = BJL1Pixel();

    self.publishButton = [self makeButtonWithTitle:@"发布" selectedTitle:@"发布" image:nil selectedImage:nil accessibilityLabel:@"publishButton"];
    [self.publishButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];
    
    self.closeButton = [self makeButtonWithTitle:@"关闭" selectedTitle:@"关闭" image:nil selectedImage:nil accessibilityLabel:@"publishButton"];
    [self.closeButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];

    self.showNickNameButton.titleEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace, 0, 0);
    self.showNickNameButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace);

    self.showNickNameButton = [self makeButtonWithTitle:@"显示昵称"
                                          selectedTitle:@"显示昵称" image:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_normal"]
                                          selectedImage:[UIImage bjlic_imageNamed:@"bjl_chat_checkbox_selected"]
                                     accessibilityLabel:@"showNickNameButton"];
    self.showNickNameButton.titleEdgeInsets = UIEdgeInsetsMake(0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace, 0, 0);
    self.showNickNameButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, [BJLIcAppearance sharedAppearance].chatViewSmallSpace);
    
    self.restrictTimeButton = ({
        UIButton *button = [UIButton new];
        [button setTitleColor:[UIColor bjl_colorWithHex:0xDBDBDB] forState:UIControlStateNormal];
        [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        button.accessibilityLabel = BJLKeypath(self, restrictTimeButton);
        [button setBackgroundColor:[UIColor bjl_colorWithHex:0x000000 alpha:0.3]];
        button.layer.cornerRadius = 4.0;
        [button setTitle:@"0" forState:UIControlStateNormal];
        bjl_return button;
    });
    self.restrictTime = @"0";
    
    self.pageNumberLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.layer.cornerRadius = 4.0;
        label.clipsToBounds = YES;
        label.textColor = [UIColor bjl_colorWithHex:0xD8D8D8];
        label.accessibilityLabel = BJLKeypath(self, pageNumberLabel);
        label.text = @"1/1";
        bjl_return label;
    });
    
    self.timeForTeachLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:12.0];
        label.textColor = [UIColor bjl_colorWithHex:0xD8D8D8];
        label.backgroundColor = [UIColor clearColor];
        label.accessibilityLabel = BJLKeypath(self, timeForTeachLabel);
        label.text = @"";
        bjl_return label;
    });

    //student
    self.submitButton = [self makeButtonWithTitle:@"提交" selectedTitle:@"提交" image:nil selectedImage:nil accessibilityLabel:@"submitButton"];
    [self.submitButton setBackgroundColor:[UIColor bjl_colorWithHex:0x1795FF]];

    self.timeForStuLabel = ({
        UILabel *label = [UILabel new];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.accessibilityLabel = BJLKeypath(self, timeForStuLabel);
        label.text = @"";
        bjl_return label;
    });
}

- (void)updateViewConstraintsWithStatus:(BJLIcWriteBoardStatus)status
                    shouldshareUserName:(BOOL)shouldshareUserName {
    self.barStyle = status;
    
    self.timeForStuLabel.text = @"";
    self.timeForTeachLabel.text = @"";
    [self.containView removeFromSuperview];
    for (UIView *subView in self.containView.subviews) {
        [subView removeFromSuperview];
    }

    [self makeConstraints];
    self.showNickNameButton.selected = (shouldshareUserName && status == BJLIcWriteBoardStatus_teacherShare);
}

- (void)updateInputTimeString:(nullable NSString *)timeString {
    self.restrictTime = (timeString.length) ? timeString : @"0";
    [self.restrictTimeButton setTitle:self.restrictTime forState:UIControlStateNormal];
}

#pragma mark - private
- (void)makeConstraints {
    [self.view addSubview:self.containView];
    [self.containView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(self.view);
    }];
    
    switch (self.barStyle) {
        case BJLIcWriteBoardStatus_teacherEditing:
            [self makeContraintsForTeacherEditing];
            break;
        case BJLIcWriteBoardStatus_teacherPublished:
            [self makeContraintsForteacherPublished];
            break;
        case BJLIcWriteBoardStatus_teacherGathered:
            [self makeContraintsForteacherGathered];
            break;
        case BJLIcWriteBoardStatus_teacherShare:
            [self makeContraintsForteacherShare];
            break;
        case BJLIcWriteBoardStatus_studentEdit:
            [self makeContraintsForstudentEdit];
            break;
        default:
            break;
    }
}

- (void)makeContraintsForTeacherEditing {
//    [self.containView addSubview:self.pictureButton];
    [self.containView addSubview:self.clearButton];
    
    UILabel *leftLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentRight;
        label.text = @"倒计时";
        bjl_return label;
    });
    
    UILabel *rightLabel = ({
        UILabel *label = [UILabel new];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment =NSTextAlignmentLeft;
        label.text = @"分钟后收回";
        bjl_return label;
    });
    
    [self.containView addSubview:leftLabel];
    [self.containView addSubview:rightLabel];
    [self.containView addSubview:self.restrictTimeButton];
    [self updateInputTimeString:@"0"];
    [self.containView addSubview:self.publishButton];
    
//    [self.pictureButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.centerY.equalTo(self.containView);
//        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
//        make.width.equalTo(@(0));
//        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
//    }];
    [self.clearButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    [self.restrictTimeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@(40));
    }];
    [leftLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.restrictTimeButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.left.greaterThanOrEqualTo(self.clearButton.bjl_right);
    }];
    [rightLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(self.restrictTimeButton.bjl_right).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.right.lessThanOrEqualTo(self.publishButton.bjl_left);
    }];
    [self.publishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherPublished {
    [self.containView addSubview:self.timeForTeachLabel];
    [self.containView addSubview:self.prevPageButton];
    [self.containView addSubview:self.nextPageButton];
    
    UIView *pageNumberContainerView = [UIView new];
    pageNumberContainerView.backgroundColor = [UIColor clearColor];
    pageNumberContainerView.layer.cornerRadius = 4.0;
    pageNumberContainerView.clipsToBounds = YES;
    pageNumberContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self.containView addSubview:pageNumberContainerView];

    [self.containView addSubview:self.pageNumberLabel];
    [self.containView addSubview:self.revokeButton];
    [self.containView addSubview:self.gatherButton];

    [self.timeForTeachLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    [self.prevPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(pageNumberContainerView.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(self.timeForTeachLabel);
        make.left.greaterThanOrEqualTo(self.timeForTeachLabel.bjl_right);
    }];
    [pageNumberContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.timeForTeachLabel);
    }];
    
    [self.pageNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.timeForTeachLabel);
        make.left.equalTo(pageNumberContainerView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.right.equalTo(pageNumberContainerView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
    }];
    [self.nextPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(pageNumberContainerView.bjl_right).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(self.timeForTeachLabel);
        make.right.lessThanOrEqualTo(self.revokeButton.bjl_left);
    }];
    [self.revokeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.timeForTeachLabel);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
        make.right.equalTo(self.gatherButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    
    [self.gatherButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.height.equalTo(self.timeForTeachLabel);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherGathered {
//    [self.containView addSubview:self.pictureButton];
    [self.containView addSubview:self.prevPageButton];
    [self.containView addSubview:self.nextPageButton];
    
    UIView *pageNumberContainerView = [UIView new];
    pageNumberContainerView.backgroundColor = [UIColor clearColor];
    pageNumberContainerView.layer.cornerRadius = 4.0;
    pageNumberContainerView.clipsToBounds = YES;
    pageNumberContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self.containView addSubview:pageNumberContainerView];

    [self.containView addSubview:self.pageNumberLabel];
    [self.containView addSubview:self.reEditButton];
    [self.containView addSubview:self.rePublishButton];
    
//    [self.pictureButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.centerY.equalTo(self.containView);
//        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
//        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
//    }];

    [self.prevPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(pageNumberContainerView.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.left.greaterThanOrEqualTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    [pageNumberContainerView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.prevPageButton);
    }];
    
    [self.pageNumberLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.height.equalTo(self.prevPageButton);
        make.left.equalTo(pageNumberContainerView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.right.equalTo(pageNumberContainerView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
    }];
    
    [self.nextPageButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.left.equalTo(pageNumberContainerView.bjl_right).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace / 2);
        make.height.equalTo(self.prevPageButton);
        make.right.lessThanOrEqualTo(self.reEditButton.bjl_left);
    }];
    
    [self.reEditButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.prevPageButton);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
        make.right.equalTo(self.rePublishButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    
    [self.rePublishButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.height.equalTo(self.prevPageButton);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
    }];
}

- (void)makeContraintsForteacherShare {
//    [self.containView addSubview:self.pictureButton];
    [self.containView addSubview:self.showNickNameButton];

    [self.containView addSubview:self.closeButton];

//    [self.pictureButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.centerY.equalTo(self.containView);
//        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
//        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
//    }];

    [self.closeButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
    }];
    
    [self.showNickNameButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(self.closeButton);
        make.width.equalTo(@(80));
        make.right.equalTo(self.closeButton.bjl_left).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
}

- (void)makeContraintsForstudentEdit {
//    [self.containView addSubview:self.pictureButton];
    [self.containView addSubview:self.clearButton];
    [self.containView addSubview:self.timeForStuLabel];
    [self.containView addSubview:self.submitButton];
    
//    [self.pictureButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
//        make.centerY.equalTo(self.containView);
//        make.height.equalTo(@(WriteBoardToolBarButtonHeight));
//        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
//    }];
    [self.clearButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.height.equalTo(@(WriteBoardToolBarButtonHeight + 2));
        make.left.equalTo(self.containView).offset([BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
    }];
    
    [self.timeForStuLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.center.equalTo(self.containView);
        make.left.greaterThanOrEqualTo(self.clearButton.bjl_right);
        make.right.lessThanOrEqualTo(self.submitButton.bjl_left);
    }];
    [self.submitButton bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.containView);
        make.right.equalTo(self.containView).offset(-[BJLIcAppearance sharedAppearance].writingBoradToolbarSmallSpace);
        make.height.equalTo(self.clearButton);
        make.width.equalTo(@([BJLIcAppearance sharedAppearance].writingBoradToolbarButtonWidth));
    }];
}

- (UIButton *)makeImageButton:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage {
    UIButton *button = [BJLImageButton new];
    button.layer.masksToBounds = YES;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button setImage:selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];

    return button;
}

- (UIButton *)makeButtonWithTitle:(nullable NSString *)title selectedTitle:(nullable NSString *)selectedTitle
                            image:(nullable UIImage *)image selectedImage:(nullable UIImage *)selectedImage
               accessibilityLabel:(nullable NSString *)accessibilityLabel {
    UIButton *button = [BJLButton new];
    button.layer.masksToBounds = YES;
    button.accessibilityLabel = accessibilityLabel;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0];
    button.layer.cornerRadius = 4.0;

    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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

@end
