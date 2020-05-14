//
//  BJLIcUserTableViewCell.m
//  BJLiveUI-BJLInteractiveClass
//
//  Created by xijia dai on 2018/10/25.
//  Copyright © 2018年 BaijiaYun. All rights reserved.
//

#import <BJLiveBase/BJLiveBase.h>

#import "BJLIcUserTableViewCell.h"
#import "BJLIcAppearance.h"

NS_ASSUME_NONNULL_BEGIN

NSString
* const BJLIcOnStageTableViewCellReuseIdentifier = @"kIcOnStageTableViewCellReuseIdentifier",
* const BJLIcDownStageTableViewCellReuseIdentifier = @"kIcDownStageTableViewCellReuseIdentifier",
* const BJLIcBlockedUserTableViewCellReuseIdentifier = @"kIcBlockedUserTableViewCellReuseIdentifier",
* const BJLIcOnlineUserTableViewCellReuseIdentifier = @"kIcOnlineUserTableViewCellReuseIdentifier",
* const BJLIcSpeakRequestUserTableViewCellReuseIdentifier = @"kIcSpeakRequestUserTableViewCellReuseIdentifier";

@interface BJLIcUserTableViewCell ()

@property (nonatomic) BJLUser *user;
@property (nonatomic) UIImageView *userAvatarImageView;
@property (nonatomic) UILabel *userNameLabel;
@property (nonatomic) UIButton *allowSpeakRequestButton, *refuseSpeakRequestButton;
@property (nonatomic) UIButton *goOnStageButton;
@property (nonatomic) UIButton *goDownStageButton;
@property (nonatomic) UIButton *forbidChatButton;
@property (nonatomic) UIButton *blockUserButton;
@property (nonatomic) UIButton *freeBlockedUserButton;
@property (nonatomic) UILabel *groupColorLabel, *groupNameLabel;

@end

@implementation BJLIcUserTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self makeSubviewsAndConstraints];
    }
    return self;
}

#pragma mark - update

- (void)updateWithUser:(BJLUser *)user
        disableOptions:(BOOL)disableOptions
        canSwitchStage:(BOOL)canSwitchStage
             groupInfo:(nullable BJLUserGroup *)groupInfo {
    self.user = user;
    NSString *urlString = BJLAliIMG_aspectFit(CGSizeMake([BJLIcAppearance sharedAppearance].userCellAvatarSize, [BJLIcAppearance sharedAppearance].userCellAvatarSize),
                                              0.0,
                                              user.avatar,
                                              nil);
    [self.userAvatarImageView bjl_setImageWithURL:[NSURL URLWithString:urlString]];
    self.userNameLabel.text = user.displayName;
    
    // 下台列表显示上台按钮
    BOOL downStageCell = [self.reuseIdentifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier];
    // 上台列表显示下台按钮
    BOOL onStageCell = [self.reuseIdentifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier];
    // 举手列表显示同意和拒绝，不显示禁言和踢出教室
    BOOL handUpCell = [self.reuseIdentifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier];
    // 黑名单仅显示取消踢出用户
    BOOL blockUserCell = [self.reuseIdentifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier];
    
    if (disableOptions) {
        self.allowSpeakRequestButton.hidden = YES;
        self.refuseSpeakRequestButton.hidden = YES;
        // 能显示上下台操作的用户根据当前是在上台还是下台列表中显示按钮
        self.goOnStageButton.hidden = canSwitchStage ? !downStageCell : YES;
        self.goDownStageButton.hidden = canSwitchStage ? !onStageCell  : YES;
        self.forbidChatButton.hidden = YES;
        self.blockUserButton.hidden = YES;
    }
    else {
        self.allowSpeakRequestButton.hidden = !handUpCell;
        self.refuseSpeakRequestButton.hidden = !handUpCell;
        self.goOnStageButton.hidden = !downStageCell;
        self.goDownStageButton.hidden = !onStageCell;
        self.forbidChatButton.hidden = handUpCell;
        self.blockUserButton.hidden = handUpCell;
    }
    if (blockUserCell) {
        [self remakeConstraintsWithButtons:@[self.freeBlockedUserButton]];
    }
    else if (handUpCell) {
        [self remakeConstraintsWithButtons:@[self.allowSpeakRequestButton, self.refuseSpeakRequestButton]];
    }
    else {
        [self remakeConstraintsWithButtons:@[self.goOnStageButton, self.goDownStageButton, self.forbidChatButton, self.blockUserButton]];
    }

    self.groupColorLabel.hidden = !handUpCell;
    self.groupNameLabel.hidden = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) || !handUpCell;
    if (groupInfo.color.length) {
        self.groupColorLabel.backgroundColor = [UIColor bjl_colorWithHexString:groupInfo.color];
    }
    else {
        self.groupColorLabel.backgroundColor = [UIColor clearColor];
    }

    self.groupNameLabel.text = groupInfo.name;
}

#pragma mark - subviews

- (void)makeSubviewsAndConstraints {
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    UIView *shadowView = ({
        UIView *view = [UIView new];
        view.backgroundColor = [UIColor clearColor];
        view.layer.masksToBounds = NO;
        view.layer.shadowOpacity = 0.3;
        view.layer.shadowColor = [UIColor blackColor].CGColor;
        view.layer.shadowOffset = CGSizeMake(0.0, 5.0);
        view.layer.shadowRadius = 10.0;
        view;
    });
    [self.contentView addSubview:shadowView];
    [shadowView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.centerY.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset([BJLIcAppearance sharedAppearance].userViewSmallSpace);
        make.left.equalTo(self.contentView).offset([BJLIcAppearance sharedAppearance].userViewLargeSpace);
        make.width.height.equalTo(@([BJLIcAppearance sharedAppearance].userCellAvatarSize));
    }];
    
    self.userAvatarImageView = ({
        UIImageView *imageView = [UIImageView new];
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = [BJLIcAppearance sharedAppearance].userCellAvatarSize / 2.0;
        imageView;
    });
    [shadowView addSubview:self.userAvatarImageView];
    [self.userAvatarImageView bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.edges.equalTo(shadowView);
    }];
    
    self.userNameLabel = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 1;
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:14.0];
        label;
    });
    [self.contentView addSubview:self.userNameLabel];
    [self.userNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.userAvatarImageView.bjl_right).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.centerY.equalTo(self.contentView);
    }];
    
    self.groupColorLabel = ({
        UILabel *label = [UILabel new];
        label.layer.cornerRadius = 6.0;
        label.layer.masksToBounds = YES;
        label.hidden = YES;
        label.accessibilityLabel = BJLKeypath(self, groupColorLabel);
        bjl_return label;
    });
    [self.contentView addSubview:self.groupColorLabel];
    [self.groupColorLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.userNameLabel.bjl_right).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.centerY.equalTo(self.contentView);
        make.size.equal.sizeOffset(CGSizeMake(12.0, 12.0));
    }];

    self.groupNameLabel = ({
        UILabel *label = [UILabel new];
        label.text = @"--";
        label.font = [UIFont systemFontOfSize:14.0];
        label.textColor = [UIColor bjl_colorWithHex:0XAFAFAF];
        [label setAlpha:0.5];
        label.hidden = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.accessibilityLabel = BJLKeypath(self, groupNameLabel);
        bjl_return label;
    });
    [self.contentView addSubview:self.groupNameLabel];
    [self.groupNameLabel bjl_makeConstraints:^(BJLConstraintMaker * _Nonnull make) {
        make.left.equalTo(self.groupColorLabel.bjl_right).offset([BJLIcAppearance sharedAppearance].chatViewSmallSpace);
        make.centerY.equalTo(self.contentView);
    }];

    // 创建全部按钮，默认隐藏，需要显示的时候设置为不隐藏，并且添加到视图中
    self.allowSpeakRequestButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_allow"]
                                               selectedImage:nil
                                                      action:@selector(allowSpeakRequest)];
    self.refuseSpeakRequestButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_refuse"]
                                                selectedImage:nil
                                                       action:@selector(refuseSpeakRequest)];
    self.goOnStageButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_onstage"]
                                       selectedImage:nil
                                              action:@selector(goOnStage)];
    self.goDownStageButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_downstage"]
                                         selectedImage:nil
                                                action:@selector(goDownStage)];
    self.forbidChatButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_forbidchat_normal"]
                                        selectedImage:[UIImage bjlic_imageNamed:@"bjl_userlist_forbidchat_selected"]
                                               action:@selector(forbidChat)];
    self.blockUserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_kickout"]
                                     selectedImage:nil
                                            action:@selector(blockUser)];
    self.freeBlockedUserButton = [self makeButtonWithImage:[UIImage bjlic_imageNamed:@"bjl_userlist_lock"]
                                             selectedImage:nil
                                                    action:@selector(freeBlockedUser)];
    
    NSArray *array;
    if ([self.reuseIdentifier isEqualToString:BJLIcOnStageTableViewCellReuseIdentifier]) {
        array = @[self.goDownStageButton, self.forbidChatButton, self.blockUserButton];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcDownStageTableViewCellReuseIdentifier]) {
         array = @[self.goOnStageButton, self.forbidChatButton, self.blockUserButton];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcSpeakRequestUserTableViewCellReuseIdentifier]) {
        BOOL iPhone = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone);
        self.groupColorLabel.hidden = NO;
        self.groupNameLabel.hidden = iPhone;
         array = @[self.allowSpeakRequestButton, self.refuseSpeakRequestButton];
    }
    else if ([self.reuseIdentifier isEqualToString:BJLIcBlockedUserTableViewCellReuseIdentifier]) {
        array = @[self.freeBlockedUserButton];
    }
    for (UIButton *button in array) {
        button.hidden = NO;
        [self.contentView addSubview:button];
    }
    [self remakeConstraintsWithButtons:array];
}

- (void)updateChatForbid:(BOOL)forbid {
    self.forbidChatButton.selected = forbid;
}

#pragma mark - actions

- (void)allowSpeakRequest {
    if (self.allowSpeakRequestCallback) {
        self.allowSpeakRequestCallback(self.user);
    }
}

- (void)refuseSpeakRequest {
    if (self.refuseSpeakRequestCallback) {
        self.refuseSpeakRequestCallback(self.user);
    }
}

- (void)goOnStage {
    if (self.goOnStageCallback) {
        self.goOnStageCallback(self.user);
    }
}

- (void)goDownStage {
    if (self.goDownStageCallback) {
        self.goDownStageCallback(self.user);
    }
}

- (void)forbidChat {
    if (self.user.isTeacher) {
        return;
    }
    BOOL forbid = !self.forbidChatButton.selected;
    if (self.forbidChatCallback) {
        self.forbidChatCallback(self.user, forbid);
    }
}

- (void)blockUser {
    if (self.user.isTeacher) {
        return;
    }
    if (self.blockUserCallback) {
        self.blockUserCallback(self.user);
    }
}

- (void)freeBlockedUser {
    if (self.freeBlockedUserCallback) {
        self.freeBlockedUserCallback(self.user);
    }
}

#pragma mark - wheel

- (UIButton *)makeButtonWithImage:(UIImage *)image selectedImage:(nullable UIImage *)selectedImage action:(SEL)action {
    UIButton *button = [BJLImageButton new];
    button.hidden = YES;
    [button setImage:image forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setImage:selectedImage forState:UIControlStateHighlighted];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)remakeConstraintsWithButtons:(nullable NSArray<UIButton *> *)buttons {
    UIButton *last = nil;
    for (UIButton *button in [buttons reverseObjectEnumerator]) {
        if (button.hidden) {
            continue;
        }
        [button bjl_remakeConstraints:^(BJLConstraintMaker * _Nonnull make) {
            if (last) {
                make.right.equalTo(last.bjl_left).offset(-[BJLIcAppearance sharedAppearance].userViewSmallSpace);
            }
            else {
                make.right.equalTo(self.contentView).offset(-[BJLIcAppearance sharedAppearance].userViewLargeSpace);
            }
            make.centerY.equalTo(self.contentView);
            make.height.width.equalTo(@([BJLIcAppearance sharedAppearance].userCellButtonSize));
        }];
        last = button;
    }
}

@end

NS_ASSUME_NONNULL_END
